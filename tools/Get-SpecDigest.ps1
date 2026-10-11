param(
    [Parameter(Mandatory)][string]$SpecPath,
    [string[]]$Keyword,
    [string[]]$Route,
    [string[]]$Method
)

$raw = Get-Content $SpecPath -Raw
if ($SpecPath -match '\.ya?ml$') {
    Import-Module powershell-yaml
    $spec = $raw | ConvertFrom-Yaml | ConvertTo-Json -Depth 100 | ConvertFrom-Json
} else {
    $spec = $raw | ConvertFrom-Json
}

function Resolve-Pointer($ref, $spec) {
    $t = $spec
    foreach ($p in ($ref -replace '^#/', '' -split '/')) { $t = $t.$p }
    $t
}

# Full expansion of $refs (detail mode)
function Expand-Refs($node, $spec, $depth = 0, $seen = @()) {
    if ($null -eq $node) { return $null }
    if ($depth -gt 5) { return '<max depth>' }
    if ($node -is [System.Management.Automation.PSCustomObject]) {
        if ($node.'$ref') {
            if ($seen -contains $node.'$ref') { return "<circular $($node.'$ref')>" }
            return Expand-Refs (Resolve-Pointer $node.'$ref' $spec) $spec ($depth + 1) ($seen + $node.'$ref')
        }
        $o = [ordered]@{}
        foreach ($p in $node.PSObject.Properties) { $o[$p.Name] = Expand-Refs $p.Value $spec $depth $seen }
        return $o
    }
    if ($node -is [System.Collections.IEnumerable] -and $node -isnot [string]) {
        return @($node | ForEach-Object { Expand-Refs $_ $spec $depth $seen })
    }
    $node
}

# Top-level field names only (digest mode)
function Get-Fields($node, $spec, $seen = @()) {
    if ($null -eq $node) { return @() }
    if ($node.'$ref') {
        if ($seen -contains $node.'$ref') { return @() }
        return Get-Fields (Resolve-Pointer $node.'$ref' $spec) $spec ($seen + $node.'$ref')
    }
    if ($node.type -eq 'array' -and $node.items) { return Get-Fields $node.items $spec $seen }
    $fields = @()
    foreach ($s in @($node.allOf)) { if ($s) { $fields += Get-Fields $s $spec $seen } }
    if ($node.properties) {
        foreach ($p in $node.properties.PSObject.Properties) {
            $star = if ($node.required -contains $p.Name) { '*' } else { '' }
            $fields += "$($p.Name)$star"
        }
    }
    $fields
}

function Get-BodySchema($op) {
    if ($op.requestBody) { return $op.requestBody.content.'application/json'.schema }          # OpenAPI 3
    ($op.parameters | Where-Object { $_.in -eq 'body' } | Select-Object -First 1).schema      # Swagger 2
}
function Get-ResponseSchema($op) {
    foreach ($code in '200', '201') {
        $r = $op.responses.$code
        if ($r) { if ($r.content) { return $r.content.'application/json'.schema } else { return $r.schema } }
    }
}

# Detail mode: one or more -Route / -Method pairs, matched by position.
# Example:
#   ./Get-SpecDigest.ps1 -SpecPath spec.json `
#     -Route "/api/users","/api/users/{id}" -Method "post","get"
if ($Route) {
    if (-not $Method -or $Route.Count -ne $Method.Count) {
        throw "Provide exactly one -Method value per -Route value (same count, same order). Got $($Route.Count) route(s) and $(@($Method).Count) method(s)."
    }
    for ($i = 0; $i -lt $Route.Count; $i++) {
        $r = $Route[$i]
        $m = $Method[$i].ToLower()

        $pathProp = $spec.paths.PSObject.Properties[$r]
        if (-not $pathProp) {
            Write-Warning "Route not found in spec: $r"
            continue
        }
        $opProp = $pathProp.Value.PSObject.Properties[$m]
        if (-not $opProp) {
            Write-Warning "Method '$m' not found for route '$r'"
            continue
        }

        "--- $($m.ToUpper()) $r ---"
        Expand-Refs $opProp.Value $spec | ConvertTo-Json -Depth 20
    }
    return
}

# Digest mode
$verbs = 'get', 'post', 'put', 'patch', 'delete'
foreach ($pathItem in $spec.paths.PSObject.Properties) {
    foreach ($m in $pathItem.Value.PSObject.Properties | Where-Object { $_.Name -in $verbs }) {
        $op = $m.Value
        $params = @($pathItem.Value.parameters) + @($op.parameters) |
            Where-Object { $_ -and $_.in -in 'path', 'query' } | ForEach-Object { "$($_.in):$($_.name)" }
        $body = (Get-Fields (Get-BodySchema $op) $spec | Select-Object -First 12) -join ','
        $resp = (Get-Fields (Get-ResponseSchema $op) $spec | Select-Object -First 12) -join ','
        $line = '{0,-6} {1} | tags:{2} | params:{3} | body:{4} | resp:{5} | "{6}"' -f `
            $m.Name.ToUpper(), $pathItem.Name, ($op.tags -join ','), ($params -join ','), $body, $resp, $op.summary
        if (-not $Keyword -or ($Keyword | Where-Object { $line -match [regex]::Escape($_) })) { $line }
    }
}

# Security info, so auth can be cross-checked against the human-supplied auth type
'--- security ---'
($spec.components.securitySchemes, $spec.securityDefinitions | Where-Object { $_ }) | ConvertTo-Json -Depth 6
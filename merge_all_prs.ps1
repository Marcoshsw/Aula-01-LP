# Configurações
$owner = "termuxcay"
$repo = "termuxtestes"
$coAuthor = "Co-authored-by: Marcoshsw <marcos.hebert48@gmail.com>"

# Solicita o token se não estiver definido
if (-not $env:GITHUB_TOKEN) {
    Write-Host "Por favor, defina a variável de ambiente `$env:GITHUB_TOKEN` com seu Personal Access Token do GitHub." -ForegroundColor Red
    exit
}

$headers = @{
    "Authorization" = "token $($env:GITHUB_TOKEN)"
    "Accept"        = "application/vnd.github.v3+json"
}

# Obtém as branches locais do Git (que foram criadas pelo script anterior)
$branches = git branch | Select-String "pair-extra-"

foreach ($branchLine in $branches) {
    $branchName = $branchLine.ToString().Trim().Replace("* ", "")
    
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Processando branch: $($branchName)"
    
    # 1. Criar o Pull Request
    $prBody = @{
        title = "PR Automático: $($branchName)"
        head  = $branchName
        base  = "main"
        body  = "Merge automático para conquista Pair Extraordinaire.`n`n$($coAuthor)"
    } | ConvertTo-Json

    try {
        $prUri = "https://api.github.com/repos/$($owner)/$($repo)/pulls"
        Write-Host "Criando PR..."
        $prResponse = Invoke-RestMethod -Uri $prUri -Method Post -Headers $headers -Body $prBody -ContentType "application/json"
        $prNumber = $prResponse.number
        Write-Host "PR #$($prNumber) criado com sucesso!" -ForegroundColor Green
        
        # 2. Confirmar o Merge
        $mergeBody = @{
            commit_title   = "Merge PR #$($prNumber) ($($branchName))"
            commit_message = "Merge automático de $($branchName)`n`n$($coAuthor)"
            merge_method   = "merge"
        } | ConvertTo-Json
        
        $mergeUri = "https://api.github.com/repos/$($owner)/$($repo)/pulls/$($prNumber)/merge"
        Write-Host "Confirmando Merge..."
        $mergeResponse = Invoke-RestMethod -Uri $mergeUri -Method Put -Headers $headers -Body $mergeBody -ContentType "application/json"
        
        if ($mergeResponse.merged) {
            Write-Host "PR #$($prNumber) mergeado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "Falha ao mergear PR #$($prNumber)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erro ao processar $($branchName)" -ForegroundColor Red
        if ($_.Exception.Response) {
             $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
             $errorDetails = $reader.ReadToEnd() | ConvertFrom-Json
             Write-Host "Detalhes: $($errorDetails.message)" -ForegroundColor Red
             if ($errorDetails.errors) {
                 Write-Host "Erros: $($errorDetails.errors | Out-String)" -ForegroundColor Red
             }
        } else {
             Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}

Write-Host "`nConcluído! Verifique seu repositório no GitHub." -ForegroundColor Cyan

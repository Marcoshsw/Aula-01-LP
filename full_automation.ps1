# Configurações para Nível PLATINUM (x4) - 1024 PRs
$owner = "Marcoshsw"
$repo = "Aula-01-LP"
$coAuthor = "Co-authored-by: termuxcay <nossyac147@gmail.com>"

# Carrega o token do arquivo .env ou da variável de ambiente
if (Test-Path ".env") {
    $envVars = Get-Content ".env" | ConvertFrom-StringData
    $token = $envVars.GITHUB_TOKEN
} else {
    $token = $env:GITHUB_TOKEN
}

if (-not $token) {
    Write-Host "ERRO: Token não encontrado. Crie um arquivo .env com GITHUB_TOKEN=seu_token" -ForegroundColor Red
    exit
}

$headers = @{
    "Authorization" = "token $token"
    "Accept"        = "application/vnd.github.v3+json"
}

# Lista de palavras para nomes aleatórios
$randomWords = @("pato", "banana", "lua", "estrela", "sol", "nuvem", "mar", "rio", "montanha", "fogo", "agua", "terra", "ar", "vento", "chuva", "neve", "pedra", "ouro", "prata", "ferro", "cobre", "bronze", "madeira", "papel", "caneta", "livro", "computador", "teclado", "mouse", "monitor", "fone", "microfone", "camera", "celular", "tablet", "relogio", "oculos", "bone", "sapato", "meia", "calca", "camisa", "casaco", "luva", "cachecol", "chapeu", "anel", "brinco")

# Garante que estamos na main
git checkout main
git pull origin main

# Alvo: 1024 novos PRs (iniciando do zero)
for ($i = 1; $i -le 1024; $i++) {
    $randomSuffix = Get-Random -Minimum 100000 -Maximum 999999
    $word = $randomWords[$i % $randomWords.Count]
    $randomName = "$word-platinum-$randomSuffix"
    $branchName = "pair-platinum-$randomName"
    $fileName = "platinum-log-$randomName.txt"
    
    Write-Host "`n" + ("="*50) -ForegroundColor Cyan
    Write-Host "Processando PR Platinum $i/900: $branchName" -ForegroundColor Cyan
    
    # 1. Criar branch e commit local
    git checkout -b $branchName
    "Platinum Automation $i em $(Get-Date)" | Out-File -FilePath $fileName
    git add $fileName
    $commitMsg = "platinum add bct $randomName`ndsadas111 $i`n`n$coAuthor"
    git commit -m "$commitMsg"
    
    # 2. Push para o GitHub
    Write-Host "Enviando branch..."
    git push origin $branchName
    
    # 3. Criar Pull Request via API
    try {
        $prBody = @{
            title = "PR Platinum #$($i): $($branchName)"
            head  = $branchName
            base  = "main"
            body  = "Rumo ao Platinum (x4) - Pair/Shark Automation.`n`n$($coAuthor)"
        } | ConvertTo-Json
        
        $prUri = "https://api.github.com/repos/$owner/$repo/pulls"
        $prResponse = Invoke-RestMethod -Uri $prUri -Method Post -Headers $headers -Body $prBody -ContentType "application/json"
        $prNumber = $prResponse.number
        Write-Host "PR #$prNumber criado!" -ForegroundColor Green
        
        # 4. Confirmar Merge via API
        $mergeBody = @{
            commit_title   = "Merge Platinum PR #$prNumber"
            commit_message = "Merge automático Platinum de $branchName`n`n$coAuthor"
            merge_method   = "merge"
        } | ConvertTo-Json
        
        $mergeUri = "https://api.github.com/repos/$owner/$repo/pulls/$prNumber/merge"
        $mergeResponse = Invoke-RestMethod -Uri $mergeUri -Method Put -Headers $headers -Body $mergeBody -ContentType "application/json"
        
        if ($mergeResponse.merged) {
            Write-Host "PR #$prNumber mergeado!" -ForegroundColor Green
        }
        
        # Pausa curta para evitar detecção de abuso (GitHub limita ações rápidas)
        Start-Sleep -Seconds 1
    } catch {
        $msg = $_.Exception.Message
        Write-Host "Erro na API: $msg" -ForegroundColor Red
        
        # Se for limite de abuso (403), espera mais tempo (60 segundos)
        if ($msg -like "*403*") {
            Write-Host "Limite de abuso atingido! Esperando 60 segundos antes de tentar novamente..." -ForegroundColor Yellow
            Start-Sleep -Seconds 60
            $i-- # Tenta o mesmo índice novamente
        }
    }
    
    # 5. Voltar para main para o próximo ciclo
    git checkout main
}

Write-Host "`nAutomação Platinum concluída! Em breve seu badge x4 aparecerá." -ForegroundColor Green

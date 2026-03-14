# Configurações do Co-Autor
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

for ($i = 1; $i -le 1024; $i++) {
    $randomSuffix = Get-Random -Minimum 100000 -Maximum 999999
    $word = $randomWords[$i % $randomWords.Count]
    $randomName = "$word-patch-$randomSuffix"
    $branchName = "pair-extra-$randomName"
    $fileName = "log-$randomName.txt"
    
    Write-Host "`n" + ("="*50) -ForegroundColor Cyan
    Write-Host "Processando PR $i/1024: $branchName" -ForegroundColor Cyan
    
    # 1. Criar branch e commit local
    git checkout -b $branchName
    "Log do commit $i em $(Get-Date)" | Out-File -FilePath $fileName
    git add $fileName
    $commitMsg = "add bct $randomName`ndsadas111 $i`n`n$coAuthor"
    git commit -m "$commitMsg"
    
    # 2. Push para o GitHub
    Write-Host "Enviando branch..."
    git push origin $branchName
    
    # 3. Criar Pull Request via API
    try {
        $prBody = @{
            title = "PR #$($i): $($branchName)"
            head  = $branchName
            base  = "main"
            body  = "Automação de PRs.`n`n$($coAuthor)"
        } | ConvertTo-Json
        
        $prUri = "https://api.github.com/repos/$owner/$repo/pulls"
        $prResponse = Invoke-RestMethod -Uri $prUri -Method Post -Headers $headers -Body $prBody -ContentType "application/json"
        $prNumber = $prResponse.number
        Write-Host "PR #$prNumber criado!" -ForegroundColor Green
        
        # 4. Confirmar Merge via API
        $mergeBody = @{
            commit_title   = "Merge PR #$prNumber"
            commit_message = "Merge automático de $branchName`n`n$coAuthor"
            merge_method   = "merge"
        } | ConvertTo-Json
        
        $mergeUri = "https://api.github.com/repos/$owner/$repo/pulls/$prNumber/merge"
        $mergeResponse = Invoke-RestMethod -Uri $mergeUri -Method Put -Headers $headers -Body $mergeBody -ContentType "application/json"
        
        if ($mergeResponse.merged) {
            Write-Host "PR #$prNumber mergeado!" -ForegroundColor Green
        }
        
        # Pausa curta para evitar detecção de abuso
        Start-Sleep -Seconds 1
    } catch {
        $msg = $_.Exception.Message
        Write-Host "Erro na API: $msg" -ForegroundColor Red
        
        if ($msg -like "*403*") {
            Write-Host "Limite de abuso atingido! Esperando 60 segundos..." -ForegroundColor Yellow
            Start-Sleep -Seconds 60
            $i--
        }
    }
    
    # 5. Voltar para main
    git checkout main
}

Write-Host "`nConcluído! Você criou e mergeou 1024 Pull Requests." -ForegroundColor Green

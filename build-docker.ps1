# build-docker.ps1 - Script pour builder l'OS avec Docker

param(
    [string]$Action = "build"
)

$IMAGE_NAME = "myos-builder"
$CONTAINER_NAME = "myos-build-container"

function Build-Image {
    Write-Host "==> Building Docker image (cette étape peut prendre 20-30 minutes la première fois)..." -ForegroundColor Cyan
    docker build -t $IMAGE_NAME .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to build Docker image" -ForegroundColor Red
        exit 1
    }
    Write-Host "==> Docker image built successfully!" -ForegroundColor Green
}

function Build-OS {
    # Vérifier si l'image existe
    $imageExists = docker images -q $IMAGE_NAME
    if (-not $imageExists) {
        Write-Host "Docker image not found. Building it first..." -ForegroundColor Yellow
        Build-Image
    }

    Write-Host "==> Building OS in Docker container..." -ForegroundColor Cyan
    
    # Lancer le container et builder
    docker run --rm `
        -v "${PWD}:/workspace" `
        $IMAGE_NAME `
        bash -c "cd /workspace && make clean && make"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Build failed" -ForegroundColor Red
        exit 1
    }
    
    # Vérifier que le fichier existe
    if (Test-Path "build/os.img") {
        $size = (Get-Item "build/os.img").Length
        Write-Host "==> Build complete! Image: build/os.img ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "Error: build/os.img was not created!" -ForegroundColor Red
        exit 1
    }
}

function Run-OS {
    if (-not (Test-Path "build/os.img")) {
        Write-Host "OS image not found. Building first..." -ForegroundColor Yellow
        Build-OS
    }
    
    Write-Host "==> Running OS in QEMU (via Docker)..." -ForegroundColor Cyan
    docker run --rm `
        -v "${PWD}:/workspace" `
        $IMAGE_NAME `
        qemu-system-x86_64 -drive format=raw,file=/workspace/build/os.img -nographic
}

function Run-OS-Local {
    if (-not (Test-Path "build/os.img")) {
        Write-Host "OS image not found. Building first..." -ForegroundColor Yellow
        Build-OS
    }
    
    Write-Host "==> Running OS with local QEMU..." -ForegroundColor Cyan
    qemu-system-x86_64 -drive format=raw,file=build/os.img
}

function Debug-OS {
    if (-not (Test-Path "build/os.img")) {
        Write-Host "OS image not found. Building first..." -ForegroundColor Yellow
        Build-OS
    }
    
    Write-Host "==> Running OS in debug mode (GDB server on port 1234)..." -ForegroundColor Cyan
    Write-Host "In another terminal, run: docker run --rm -it -v ${PWD}:/workspace $IMAGE_NAME gdb" -ForegroundColor Yellow
    Write-Host "Then in GDB: target remote localhost:1234" -ForegroundColor Yellow
    
    docker run --rm `
        -v "${PWD}:/workspace" `
        -p 1234:1234 `
        $IMAGE_NAME `
        qemu-system-x86_64 -drive format=raw,file=/workspace/build/os.img -s -S -nographic
}

function Clean-Build {
    Write-Host "==> Cleaning build directory..." -ForegroundColor Cyan
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Host "==> Clean complete!" -ForegroundColor Green
    } else {
        Write-Host "==> Build directory already clean!" -ForegroundColor Yellow
    }
}

function Enter-Shell {
    $imageExists = docker images -q $IMAGE_NAME
    if (-not $imageExists) {
        Write-Host "Docker image not found. Building it first..." -ForegroundColor Yellow
        Build-Image
    }
    
    Write-Host "==> Entering Docker shell..." -ForegroundColor Cyan
    docker run --rm -it `
        -v "${PWD}:/workspace" `
        $IMAGE_NAME `
        /bin/bash
}

# Actions
switch ($Action) {
    "image" { Build-Image }
    "build" { Build-OS }
    "run" { Run-OS-Local }
    "run-docker" { Run-OS }
    "debug" { Debug-OS }
    "clean" { Clean-Build }
    "shell" { Enter-Shell }
    default {
        Write-Host "Usage: .\build-docker.ps1 [image|build|run|run-docker|debug|clean|shell]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  image      - Build Docker image (première fois seulement)"
        Write-Host "  build      - Compile l'OS"
        Write-Host "  run        - Compile et lance avec QEMU local"
        Write-Host "  run-docker - Compile et lance avec QEMU dans Docker"
        Write-Host "  debug      - Lance en mode debug (GDB)"
        Write-Host "  clean      - Nettoie le dossier build"
        Write-Host "  shell      - Ouvre un shell dans le container"
    }
}
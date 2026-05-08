$lib = 'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'

# Mover archivos de subcarpetas de vuelta a lib
$folders = @('models', 'repositories', 'providers', 'screens', 'dialogs', 'widgets', 'theme')
foreach ($folder in $folders) {
    $path = Join-Path $lib $folder
    if (Test-Path $path) {
        Get-ChildItem -Path $path -File | Move-Item -Destination $lib -Force
        Remove-Item -Path $path -Recurse -Force
    }
}

Write-Host 'Archivos restaurados a lib/'

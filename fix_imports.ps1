$lib = 'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'
$dartFiles = Get-ChildItem -Path $lib -Filter '*.dart'

foreach ($file in $dartFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $changed = $false

    # Reemplazar imports relativos con rutas de carpetas por imports simples
    $patterns = @(
        "import 'models/",
        "import 'repositories/",
        "import 'providers/",
        "import 'screens/",
        "import 'dialogs/",
        "import 'widgets/",
        "import 'theme/",
        'import "models/',
        'import "repositories/',
        'import "providers/',
        'import "screens/',
        'import "dialogs/',
        'import "widgets/',
        'import "theme/'
    )

    foreach ($pattern in $patterns) {
        if ($content.Contains($pattern)) {
            $content = $content.Replace("import 'models/", "import '")
            $content = $content.Replace("import 'repositories/", "import '")
            $content = $content.Replace("import 'providers/", "import '")
            $content = $content.Replace("import 'screens/", "import '")
            $content = $content.Replace("import 'dialogs/", "import '")
            $content = $content.Replace("import 'widgets/", "import '")
            $content = $content.Replace("import 'theme/", "import '")
            $content = $content.Replace('import "models/', 'import "')
            $content = $content.Replace('import "repositories/', 'import "')
            $content = $content.Replace('import "providers/', 'import "')
            $content = $content.Replace('import "screens/', 'import "')
            $content = $content.Replace('import "dialogs/', 'import "')
            $content = $content.Replace('import "widgets/', 'import "')
            $content = $content.Replace('import "theme/', 'import "')
            $changed = $true
        }
    }

    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host ('Fixed: ' + $file.Name)
    }
}

Write-Host 'Done fixing imports'

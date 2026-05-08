$lib = 'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'
$dartFiles = Get-ChildItem -Path $lib -Recurse -Filter '*.dart'

$mapping = @{
    'product.dart'                    = 'models/product.dart'
    'category.dart'                   = 'models/category.dart'
    'cart_item.dart'                  = 'models/cart_item.dart'
    'sale.dart'                       = 'models/sale.dart'
    'sale_detail_item.dart'           = 'models/sale_detail_item.dart'
    'product_return.dart'             = 'models/product_return.dart'
    'category_sale.dart'              = 'models/category_sale.dart'
    'products_repository.dart'        = 'repositories/products_repository.dart'
    'sales_repository.dart'           = 'repositories/sales_repository.dart'
    'auth_repository.dart'            = 'repositories/auth_repository.dart'
    'products_provider.dart'          = 'providers/products_provider.dart'
    'cart_notifier.dart'              = 'providers/cart_notifier.dart'
    'held_carts_notifier.dart'        = 'providers/held_carts_notifier.dart'
    'suspended_sales_provider.dart'   = 'providers/suspended_sales_provider.dart'
    'theme_notifier.dart'             = 'providers/theme_notifier.dart'
    'theme_provider.dart'             = 'providers/theme_provider.dart'
    'main_screen.dart'                = 'screens/main_screen.dart'
    'pos_screen.dart'                 = 'screens/pos_screen.dart'
    'inventory_screen.dart'           = 'screens/inventory_screen.dart'
    'sales_history_screen.dart'       = 'screens/sales_history_screen.dart'
    'sale_detail_screen.dart'         = 'screens/sale_detail_screen.dart'
    'sale_completion_screen.dart'     = 'screens/sale_completion_screen.dart'
    'reports_screen.dart'             = 'screens/reports_screen.dart'
    'dead_stock_report_screen.dart'   = 'screens/dead_stock_report_screen.dart'
    'returns_screen.dart'             = 'screens/returns_screen.dart'
    'profile_screen.dart'             = 'screens/profile_screen.dart'
    'settings_screen.dart'            = 'screens/settings_screen.dart'
    'login_screen.dart'               = 'screens/login_screen.dart'
    'register_screen.dart'            = 'screens/register_screen.dart'
    'category_management_screen.dart' = 'screens/category_management_screen.dart'
    'add_product_screen.dart'         = 'screens/add_product_screen.dart'
    'add_product_dialog.dart'         = 'dialogs/add_product_dialog.dart'
    'edit_product_dialog.dart'        = 'dialogs/edit_product_dialog.dart'
    'checkout_dialog.dart'            = 'dialogs/checkout_dialog.dart'
    'new_return_dialog.dart'          = 'dialogs/new_return_dialog.dart'
    'held_carts_dialog.dart'          = 'dialogs/held_carts_dialog.dart'
    'app_shell.dart'                  = 'widgets/app_shell.dart'
    'app_sidebar.dart'                = 'widgets/app_sidebar.dart'
    'low_stock_banner.dart'           = 'widgets/low_stock_banner.dart'
    'image_picker_widget.dart'        = 'widgets/image_picker_widget.dart'
    'receipt_generator.dart'          = 'widgets/receipt_generator.dart'
    'auth_gate.dart'                  = 'widgets/auth_gate.dart'
    'dashboard_stats.dart'            = 'widgets/dashboard_stats.dart'
    'app_theme.dart'                  = 'theme/app_theme.dart'
}

foreach ($file in $dartFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    $changed = $false

    foreach ($oldFile in $mapping.Keys) {
        $newPath = $mapping[$oldFile]
        $pattern = "import '" + $oldFile + "';"

        if ($content.Contains($pattern)) {
            $relativePath = [System.IO.Path]::GetRelativePath($file.DirectoryName, "$lib\$newPath").Replace('\', '/')
            if ($relativePath.StartsWith('./')) {
                $relativePath = $relativePath.Substring(2)
            }
            $newImport = "import '" + $relativePath + "';"
            $content = $content.Replace($pattern, $newImport)
            $changed = $true
        }
    }

    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host ('Actualizado: ' + $file.FullName.Replace($lib, 'lib'))
    }
}

Write-Host 'Imports actualizados exitosamente'

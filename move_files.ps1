$lib = 'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'

# models
Move-Item -Path "$lib\product.dart", "$lib\category.dart", "$lib\cart_item.dart", "$lib\sale.dart", "$lib\sale_detail_item.dart", "$lib\product_return.dart", "$lib\category_sale.dart" -Destination "$lib\models" -Force

# repositories
Move-Item -Path "$lib\products_repository.dart", "$lib\sales_repository.dart", "$lib\auth_repository.dart" -Destination "$lib\repositories" -Force

# providers
Move-Item -Path "$lib\products_provider.dart", "$lib\cart_notifier.dart", "$lib\held_carts_notifier.dart", "$lib\suspended_sales_provider.dart", "$lib\theme_notifier.dart", "$lib\theme_provider.dart" -Destination "$lib\providers" -Force

# screens
Move-Item -Path "$lib\main_screen.dart", "$lib\pos_screen.dart", "$lib\inventory_screen.dart", "$lib\sales_history_screen.dart", "$lib\sale_detail_screen.dart", "$lib\sale_completion_screen.dart", "$lib\reports_screen.dart", "$lib\dead_stock_report_screen.dart", "$lib\returns_screen.dart", "$lib\profile_screen.dart", "$lib\settings_screen.dart", "$lib\login_screen.dart", "$lib\register_screen.dart", "$lib\category_management_screen.dart", "$lib\add_product_screen.dart" -Destination "$lib\screens" -Force

# dialogs
Move-Item -Path "$lib\add_product_dialog.dart", "$lib\edit_product_dialog.dart", "$lib\checkout_dialog.dart", "$lib\new_return_dialog.dart", "$lib\held_carts_dialog.dart" -Destination "$lib\dialogs" -Force

# widgets
Move-Item -Path "$lib\app_shell.dart", "$lib\app_sidebar.dart", "$lib\low_stock_banner.dart", "$lib\image_picker_widget.dart", "$lib\receipt_generator.dart", "$lib\auth_gate.dart", "$lib\dashboard_stats.dart" -Destination "$lib\widgets" -Force

# theme
Move-Item -Path "$lib\app_theme.dart" -Destination "$lib\theme" -Force

Write-Host 'Archivos movidos exitosamente'

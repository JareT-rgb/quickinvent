# 🔍 Auditoría Profunda — QuickInvent
> Fecha: 2026-05-05 | Estado: En progreso

---

## 1. 📊 ESTADÍSTICAS Y REPORTES (Prioridad CRÍTICA)

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 1.1 | **Todas las cifras de reportes son hardcodeadas** | 🔴 Crítica | `reports_screen.dart` muestra valores fijos: `$261,950.00`, `1142 ventas`, `31 productos`, `3 stock bajo`. No lee datos reales. |
| 1.2 | **Gráfica de barras mensuales es estática** | 🔴 Crítica | Los valores de `heightFactor` (0.3, 0.5, 0.4...) están quemados. No se calculan desde ventas reales. |
| 1.3 | **Gráfica de líneas diarias es un `CustomPainter` sin datos reales** | 🔴 Crítica | `_LineChartPainter` dibuja una curva fija. No representa ventas diarias del mes. |
| 1.4 | **Productos más vendidos son estáticos** | 🔴 Crítica | `Arroz El Toro 1kg: 327`, `Cloro Cloralex: 326`, etc. Son texto plano, no se calculan. |
| 1.5 | **Métodos de pago son estáticos** | 🔴 Crítica | Porcentajes fijos: Efectivo 61.3%, Tarjeta 25.4%, Transferencia 13.3%. |
| 1.6 | **Comparación mensual es estática** | 🔴 Crítica | Valores fijos `$30,636` vs `$74,559` con decremento del 58.9% inventado. |
| 1.7 | **Dead stock report es estático** | 🔴 Crítica | `Vinagre Clemente`, `Cajeta Coronado`, `Consomé Knorr` son filas hardcodeadas. |
| 1.8 | **DashboardStats existe pero NO se usa** | 🟡 Alta | La clase `DashboardStats` está definida pero ninguna pantalla la consume. |
| 1.9 | **No hay repositorio de ventas (`SalesRepository`)** | 🔴 Crítica | No existe un repositorio que almacene las ventas realizadas. `Sale` y `SaleDetailItem` existen como modelos pero no se persisten. |
| 1.10 | **No hay provider de ventas para estadísticas** | 🔴 Crítica | Se necesita un `salesProvider` que exponga métricas agregadas: ingresos totales, ventas por día/mes, top productos, métodos de pago. |
| 1.11 | **No hay exportación de reportes** | 🟡 Alta | El usuario no puede exportar a CSV/PDF los reportes. |

**Recomendación:** Crear `SalesRepository` con lista mutable de ventas. Al confirmar pago en `CheckoutDialog`, guardar la venta con fecha, método de pago, items, total. Luego consumir esos datos en ReportsScreen.

---

## 2. 🛒 PUNTO DE VENTA (POS)

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 2.1 | **CheckoutDialog no guarda la venta** | 🔴 Crítica | `Confirmar pago` solo navega a `SaleCompletionScreen`. No se persiste ninguna venta, no se descuenta stock, no se genera historial. |
| 2.2 | **No se descuenta stock al vender** | 🔴 Crítica | `cartNotifier` maneja el carrito, pero al cobrar no se actualiza `product.stockQuantity` en el repositorio. |
| 2.3 | **No hay control de stock mínimo en POS** | 🟡 Alta | Si un producto tiene `stockQuantity < minStock`, sigue apareciendo igual en el grid sin advertencia visual. |
| 2.4 | **Búsqueda por código de barras no funciona** | 🟡 Alta | El `TextField` de búsqueda solo filtra por nombre. No tiene lector de código de barras integrado. |
| 2.5 | **GridView no muestra imagen del producto** | 🟢 Baja | Los productos muestran un `CircleAvatar` con la primera letra. No usan `_imagePath` ni imagen real. |
| 2.6 | **No hay vista rápida de producto** | 🟢 Baja | Al hacer tap en un producto solo se añade al carrito. No hay modo de ver detalles antes. |
| 2.7 | **El carrito no muestra subtotal por línea** | 🟡 Alta | Solo muestra precio unitario, no calcula `quantity × price` por item. |
| 2.8 | **No hay botón para eliminar item del carrito** | 🟡 Alta | Solo hay `+` y `-`. Si quieres quitar un producto con cantidad 5, debes presionar `-` 5 veces. |
| 2.9 | **SaleCompletionScreen tiene botón "Imprimir" sin funcionalidad** | 🟡 Alta | `onPressed: () {}` vacío. Debería usar `receipt_generator.dart`. |
| 2.10 | **SaleCompletionScreen no limpia carrito realmente** | 🟡 Alta | `Navigator.popUntil((route) => route.isFirst)` regresa al POS, pero como `MainScreen` usa `AnimatedSwitcher`, el carrito sigue lleno hasta que se reconstruye. |
| 2.11 | **Poner en espera usa `heldCartsProvider` pero hay `suspendedSalesProvider` duplicado** | 🟡 Alta | Existen dos notificadores para lo mismo: `held_carts_notifier.dart` y `suspended_sales_provider.dart`. Solo se usa el primero. El segundo es código muerto. |
| 2.12 | **QuickAmountChip solo redondea a 10** | 🟢 Baja | El segundo chip calcula `(total / 10).ceil() * 10`, pero no hay chips para monto exacto + 20, +50, +100. |

---

## 3. 📦 INVENTARIO

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 3.1 | **AddProductDialog y AddProductScreen son redundantes** | 🟡 Alta | Hay dos pantallas/dialogs para agregar producto. `AddProductScreen` se accede desde FAB en `AppShell`, pero la app usa `MainScreen` con sidebar, no `AppShell` como raíz post-login. |
| 3.2 | **AddProductDialog usa categorías hardcodeadas** | 🔴 Crítica | Las opciones del dropdown están quemadas: `['Lácteos', 'Bebidas', 'Abarrotes', 'Frituras', 'Dulces']`. No lee de `categoriesProvider`. |
| 3.3 | **EditProductDialog no carga imagen** | 🟢 Baja | La sección de imagen solo muestra placeholder. No carga `_imagePath` ni permite cambiarla. |
| 3.4 | **EditProductDialog: "Stock inicial" debería ser "Stock actual"** | 🟡 Alta | Al editar, el label dice "Stock inicial", lo cual es confuso. Es edición, no creación. |
| 3.5 | **EditProductDialog: campo stock mínimo no tiene controller** | 🔴 Crítica | Línea 232-239 usa `initialValue: '0'` y no tiene `controller`. Pierde el valor real del producto. |
| 3.6 | **InventoryScreen: filtro de categorías muestra IDs pero compara strings** | 🟡 Alta | `categoryMap` guarda `{name: id.toString()}`, pero luego compara `p.categoryId == categoryMap[_selectedCategory]`. Si `categoryId` en producto es string numérico, funciona, pero es frágil. |
| 3.7 | **InventoryScreen: filtro "Todos" en estado muestra inactivos** | 🟡 Alta | La lógica `_showInactive = (val == 'Inactivos' || val == 'Todos')` muestra inactivos cuando se elige "Todos". Esto es correcto, pero el checkbox "Ver inactivos" y el dropdown pueden entrar en estado inconsistente. |
| 3.8 | **No hay paginación real** | 🟡 Alta | La paginación es visual (`1 / 1`, botones Anterior/Siguiente sin funcionalidad). |
| 3.9 | **Eliminar producto solo lo desactiva** | 🟡 Alta | El botón de "Eliminar" en realidad ejecuta `updateProduct(isActive: false)`. No hay opción de eliminar físicamente. |
| 3.10 | **CategoryManagementScreen es inaccesible desde la UI** | 🔴 Crítica | No hay navegación a esta pantalla desde `MainScreen` ni `AppShell`. Solo existe como archivo. |
| 3.11 | **No hay importación masiva de productos** | 🟢 Baja | No se puede importar CSV/Excel. |

---

## 4. 💰 VENTAS E HISTORIAL

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 4.1 | **SalesHistoryScreen usa datos estáticos** | 🔴 Crítica | Las filas de la tabla son hardcodeadas: `S01128`, `S01136`, `S01141`. Las tarjetas de resumen muestran `0` en "Ventas hoy", "Ingresos hoy", "Efectivo hoy". |
| 4.2 | **SalesHistoryScreen: filtro por fecha no funciona** | 🔴 Crítica | Los campos de fecha son `readOnly: true` sin `onTap` ni `showDatePicker`. |
| 4.3 | **SalesHistoryScreen: filtro por método de pago no funciona** | 🔴 Crítica | El dropdown tiene un solo item fijo: `'Todos los pagos'`. |
| 4.4 | **SalesHistoryScreen: búsqueda no funciona** | 🔴 Crítica | El TextField de búsqueda no tiene `onChanged` ni lógica de filtrado. |
| 4.5 | **No hay detalle de venta navegable desde historial** | 🟡 Alta | La columna "VER" muestra un icono sin `onPressed`. No abre `SaleDetailScreen`. |
| 4.6 | **SaleDetailScreen muestra cambio fijo como `$0.00`** | 🟡 Alta | El cambio se calcula en `CheckoutDialog` pero no se pasa a `Sale`. En `SaleDetailScreen` se muestra `$0.00` siempre. |
| 4.7 | **SaleDetailScreen: botón "Nueva venta" solo hace `Navigator.pop`** | 🟡 Alta | No limpia el carrito ni navega de forma robusta. |
| 4.8 | **No hay reembolso/void de venta completa** | 🟢 Baja | Solo hay devolución de producto individual, no anulación de venta. |

---

## 5. 🔄 DEVOLUCIONES

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 5.1 | **NewReturnDialog no guarda la devolución** | 🔴 Crítica | El botón "Procesar Devolución" solo hace `Navigator.pop(context)`. No actualiza stock, no guarda en historial. |
| 5.2 | **NewReturnDialog no valida cantidad vs stock vendido** | 🔴 Crítica | Permite ingresar cualquier cantidad sin verificar si se vendió esa cantidad del producto. |
| 5.3 | **ReturnsScreen muestra datos mock** | 🟡 Alta | `fetchReturns()` en `ProductsRepository` retorna una lista fija con un solo item (`R001`, Aceite Capullo). |
| 5.4 | **Devolución no afecta el stock del producto** | 🔴 Crítica | Al procesar devolución, no se incrementa `stockQuantity` del producto. |
| 5.5 | **Devolución no afecta el total de la venta original** | 🟡 Alta | No se vincula la devolución con la venta original para ajustar totales. |
| 5.6 | **No hay motivos de devolución predefinidos** | 🟢 Baja | El usuario escribe libremente. Podrían existir opciones rápidas: dañado, vencido, cambio, error de cobro. |

---

## 6. 🔐 AUTENTICACIÓN Y USUARIOS

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 6.1 | **LoginScreen no autentica realmente** | 🔴 Crítica | Cualquier usuario/contraseña pasa la validación. No llama a `AuthRepository.signInWithEmail`. |
| 6.2 | **RegisterScreen no registra realmente** | 🔴 Crítica | No llama a `AuthRepository.signUpWithEmail`. Solo navega al login. |
| 6.3 | **main.dart usa `home: LoginScreen()` en lugar de `AuthGate`** | 🟡 Alta | `AuthGate` existe y está bien diseñado con Riverpod, pero `main.dart` lo ignora. Esto rompe el flujo de autenticación real. |
| 6.4 | **AppShell existe pero no se usa** | 🟡 Alta | `MainScreen` es la pantalla raíz post-login. `AppShell` (con BottomNavBar) es código muerto o alternativa no conectada. |
| 6.5 | **ProfileScreen no muestra nombre del usuario** | 🟡 Alta | Muestra email de Supabase (si hay), pero no hay campo de nombre. El registro pide nombre completo pero no se guarda. |
| 6.6 | **No hay roles de usuario** | 🟢 Baja | Todos los usuarios tienen acceso total. No hay diferencia entre cajero, encargado y admin. |
| 6.7 | **No hay recuperación de contraseña desde login** | 🟡 Alta | `AuthRepository` tiene `sendPasswordResetEmail` pero la UI de login no tiene link "¿Olvidaste tu contraseña?". |
| 6.8 | **Cerrar sesión en `ProfileScreen` no navega al login** | 🔴 Crítica | `ref.read(authRepositoryProvider).signOut()` cierra sesión en Supabase, pero como `main.dart` no usa `AuthGate`, la UI no reacciona. Queda en la pantalla de perfil. |

---

## 7. ⚙️ CONFIGURACIÓN

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 7.1 | **SettingsScreen es extremadamente básico** | 🟡 Alta | Solo tiene el toggle de tema oscuro. Falta: idioma, impresora térmica, moneda, nombre de tienda, impuestos (IVA), backup. |
| 7.2 | **No hay configuración de impuestos (IVA)** | 🔴 Crítica | Todas las ventas se calculan sin IVA. Un POS real necesita agregar/quitar impuestos. |
| 7.3 | **No hay configuración de impresora** | 🟡 Alta | `receipt_generator.dart` genera PDF pero no hay configuración de selección de impresora, tamaño de papel, etc. |
| 7.4 | **Tema se maneja en dos lados diferentes** | 🟢 Baja | `theme_notifier.dart` maneja el tema para `main.dart`, pero `profile_screen.dart` y `settings_screen.dart` también lo controlan. Es confuso. |

---

## 8. 🎨 DISEÑO Y UI/UX

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 8.1 | **Inconsistencia entre MainScreen y AppShell** | 🟡 Alta | `MainScreen` usa sidebar lateral (desktop). `AppShell` usa bottom navbar (mobile). La app no detecta el tamaño de pantalla para elegir uno u otro. |
| 8.2 | **RegisterScreen y LoginScreen no son responsive** | 🟡 Alta | En pantallas pequeñas (tablets/móviles), el layout de dos columnas se rompe. No hay `LayoutBuilder` ni breakpoints. |
| 8.3 | **POS no tiene estado vacío atractivo** | 🟢 Baja | Cuando no hay productos, solo muestra texto gris. Podría tener ilustración y CTA. |
| 8.4 | **ReportsScreen no tiene selector de rango de fechas** | 🟡 Alta | No se puede filtrar reportes por fecha personalizada. |
| 8.5 | **Los colores están hardcodeados en múltiples archivos** | 🟢 Baja | `Color(0xFF8BC34A)`, `Color(0xFF2E7D32)`, etc. se repiten. Deberían estar en un tema centralizado. |
| 8.6 | **No hay animaciones de transición entre pantallas** | 🟢 Baja | `AnimatedSwitcher` en `MainScreen` es básico. No hay transiciones suaves entre secciones. |
| 8.7 | **AppSidebar no tiene indicador visual de badge dinámico** | 🟢 Baja | El parámetro `badge` existe en `_buildItem` pero nunca se pasa. Podría mostrar stock bajo o devoluciones pendientes. |
| 8.8 | **No hay modo oscuro completo** | 🟡 Alta | `theme_notifier.dart` cambia el tema, pero muchas pantallas usan colores hardcodeados (`Colors.grey.shade100`, `Color(0xFFF8F9FA)`) que no responden al tema oscuro. |
| 8.9 | **No hay feedback táctil/háptico en acciones importantes** | 🟢 Baja | Al cobrar, guardar, eliminar, no hay vibración ni sonido. |

---

## 9. 🏗️ ARQUITECTURA Y CÓDIGO TÉCNICO

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| 9.1 | **ProductsRepository es un singleton con datos en memoria** | 🟡 Alta | Al reiniciar la app, se pierden todos los productos, ventas, devoluciones. No hay persistencia local (SQLite/Drift/Hive). |
| 9.2 | **No hay manejo de errores de red/Supabase** | 🔴 Crítica | `AuthRepository` usa Supabase pero si falla la conexión, la app crashea sin mensaje claro. |
| 9.3 | **Dependencia `go_router` instalada pero NO usada** | 🟢 Baja | `pubspec.yaml` incluye `go_router: ^17.2.3` pero todo usa `Navigator.push`/`MaterialPageRoute`. |
| 9.4 | **Modelos `Sale` y `SaleDetailItem` no tienen relación** | 🟡 Alta | `SaleDetailItem` no referencia el `saleId`. El método `fetchSaleDetails` recibe un `int` pero no hay forma de saber qué items pertenecen a qué venta en el modelo. |
| 9.5 | **Existe `theme_provider.dart` que solo re-exporta** | 🟢 Baja | Archivo innecesario. `theme_notifier.dart` ya exporta todo lo necesario. |
| 9.6 | **Existe `suspended_sales_provider.dart` no usado** | 🟢 Baja | Código muerto. Se usa `held_carts_notifier.dart` en su lugar. |
| 9.7 | **No hay tests unitarios ni de widget** | 🟡 Alta | El proyecto tiene `flutter_test` en dev_dependencies pero no hay archivos de test. |
| 9.8 | **InventoryScreen usa `dynamic` en `_buildDataRow`** | 🟢 Baja | `DataRow _buildDataRow(dynamic p, ...)` en lugar de `Product p`. Pierde type safety. |
| 9.9 | **POS usa `List<dynamic> cart` en `_buildTotalSection`** | 🟢 Baja | Debería ser `List<CartItem>`. |
| 9.10 | **CheckoutDialog no valida que el monto recibido >= total** | 🟡 Alta | Permite confirmar pago con monto insuficiente. El cambio quedaría negativo. |

---

## 10. 🚀 FUNCIONALIDADES FALTANTES (NUEVAS)

| # | Funcionalidad | Impacto | Descripción |
|---|---------------|---------|-------------|
| 10.1 | **Cierre de caja (Cash closing)** | 🔴 Crítica | Reporte de cuánto efectivo debería haber en caja al final del turno. |
| 10.2 | **Alertas de stock por notificación** | 🟡 Alta | Cuando un producto baja de `minStock`, mostrar badge o notificación. |
| 10.3 | **Código de barras con cámara** | 🟡 Alta | Usar `mobile_scanner` o similar para escanear códigos de barras en POS e Inventario. |
| 10.4 | **Gestión de proveedores** | 🟢 Baja | Registrar proveedores y asociarlos a productos. |
| 10.5 | **Órdenes de compra sugeridas** | 🟢 Baja | Basado en stock bajo, sugerir cantidades a reordenar. |
| 10.6 | **Múltiples cajas/turnos** | 🟢 Baja | Si hay varios empleados, registrar quién atendió cada venta. |
| 10.7 | **Descuentos y promociones** | 🟡 Alta | Aplicar descuentos por porcentaje o monto fijo en el carrito. |
| 10.8 | **Clientes frecuentes / CRM básico** | 🟢 Baja | Registrar clientes y su historial de compras. |

---

## 📋 RESUMEN EJECUTIVO

| Categoría | 🔴 Críticos | 🟡 Altos | 🟢 Bajos |
|-----------|-------------|----------|----------|
| Datos/Reportes | 10 | 1 | 0 |
| POS | 2 | 7 | 3 |
| Inventario | 2 | 7 | 2 |
| Ventas/Historial | 4 | 3 | 1 |
| Devoluciones | 3 | 2 | 1 |
| Autenticación | 3 | 3 | 1 |
| Configuración | 1 | 2 | 1 |
| Diseño/UX | 0 | 4 | 5 |
| Arquitectura | 2 | 3 | 5 |
| **Nuevas funciones** | 1 | 2 | 5 |
| **TOTAL** | **28** | **34** | **24** |

### 🔥 Top 5 Prioridades Inmediatas
1. **Crear `SalesRepository` y persistir ventas** — Todo el reporte y el historial dependen de esto.
2. **Conectar `CheckoutDialog` → guardar venta + descontar stock** — El núcleo del POS no funciona sin esto.
3. **Crear providers de estadísticas reales** — Reemplazar todas las cifras hardcodeadas de `ReportsScreen` y `SalesHistoryScreen`.
4. **Corregir `main.dart` para usar `AuthGate` en lugar de `LoginScreen`** — Habilitar autenticación real.
5. **Unificar navegación: decidir entre `MainScreen` (sidebar) o `AppShell` (bottom nav)** — Eliminar confusión arquitectónica.

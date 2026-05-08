# Diagrama de Arquitectura MVVM - QuickInvent

Aquí tienes el diagrama de la arquitectura de tu proyecto (QuickInvent) basado en el modelo MVVM que proporcionaste, adaptado con las tecnologías y clases que realmente estamos usando (Riverpod en lugar de ChangeNotifier, y tus entidades reales).

Puedes copiar este código Mermaid en tu documentación o en herramientas como [Mermaid Live Editor](https://mermaid.live/) para generar la imagen.

```mermaid
flowchart TD
    %% Estilos
    classDef presentation fill:#4a4e69,stroke:#22223b,stroke-width:2px,color:#fff;
    classDef view fill:#6b705c,stroke:#3f4238,stroke-width:2px,color:#fff;
    classDef viewmodel fill:#a5a58d,stroke:#6b705c,stroke-width:2px,color:#fff;
    classDef domain fill:#264653,stroke:#1d3557,stroke-width:2px,color:#fff;
    classDef interface fill:#2a9d8f,stroke:#21867a,stroke-width:2px,color:#fff;
    classDef entity fill:#e9c46a,stroke:#c9a227,stroke-width:2px,color:#333;
    classDef data fill:#f4a261,stroke:#e76f51,stroke-width:2px,color:#fff;
    classDef repoImpl fill:#e76f51,stroke:#d00000,stroke-width:2px,color:#fff;
    classDef model fill:#e07a5f,stroke:#81b29a,stroke-width:2px,color:#fff;
    classDef external fill:#2b9348,stroke:#007f5f,stroke-width:2px,color:#fff;

    subgraph PresentationLayer [Presentation Layer]
        direction TB
        View["View\n(Screen / Widget)\nEj: PosScreen, InventoryScreen"]:::view
        
        ViewModel["ViewModel\n(Riverpod Providers)\nEj: cartProvider, productsProvider"]:::viewmodel
        
        View -- "ref.watch()\nref.read().metodo()" --> ViewModel
    end
    class PresentationLayer presentation;

    subgraph DomainLayer [Domain Layer]
        direction LR
        Interface["Domain Interface\n(Lógica de Negocio)\nEj: ProductsRepository,\nSalesRepository"]:::interface
        
        Entity["Entity\n(Clases Dart)\nEj: Product, Sale, Category"]:::entity
    end
    class DomainLayer domain;

    ViewModel -- "Llama métodos" --> Interface

    subgraph DataLayer [Data Layer]
        direction TB
        RepoImpl["Repository Implementación\n(Consultas reales a BD)"]:::repoImpl
        
        Model["Model\n(JSON ↔ Dart)\nEj: Product.fromMap(),\nSale.fromMap()"]:::model
        
        RepoImpl -- "serializa/deserializa" --> Model
    end
    class DataLayer data;

    Interface -. "Implementado por" .-> RepoImpl

    subgraph ExternalLayer [External]
        Supabase["Supabase\nPostgreSQL + Auth\n+ Storage + Realtime"]:::external
    end

    RepoImpl -- "SDK calls" --> Supabase
```

## Explicación de las Capas en QuickInvent:

1. **Presentation Layer (Capa de Presentación)**: 
   * **View**: Son tus pantallas en `lib/screens/` (ej. `pos_screen.dart`).
   * **ViewModel**: En lugar de usar el clásico `ChangeNotifier`, en QuickInvent usamos **Riverpod** (`lib/providers/`). Los widgets se comunican con el estado usando `ref.watch()` para reaccionar a cambios, y `ref.read().accion()` para disparar eventos (ej. agregar al carrito).

2. **Domain Layer (Capa de Dominio)**:
   * **Interface / Repository**: Son las clases en `lib/repositories/` (ej. `ProductsRepository`). Definen qué operaciones se pueden hacer (obtener productos, registrar venta).
   * **Entity**: Son tus objetos puros de negocio en `lib/models/` (ej. `Product`, `Sale`, `Category`).

3. **Data Layer (Capa de Datos)**:
   * **Repository Implementación**: Es el código interno de tus repositorios que hace las llamadas reales (`_client.from('products').select()`).
   * **Model (Serialización)**: Son las funciones `fromMap()` y `toMap()` dentro de tus entidades que convierten el JSON de la base de datos a objetos de Dart.

4. **External**: 
   * El Backend como Servicio (BaaS) que estamos usando: **Supabase**, que maneja la base de datos PostgreSQL, la autenticación, el almacenamiento de imágenes (Storage) y las actualizaciones en tiempo real (como los escaneos de códigos de barras).

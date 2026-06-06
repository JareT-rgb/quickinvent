import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../providers/products_provider.dart';
import '../repositories/products_repository.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final DateTime? cooldownUntil;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isError = false,
    this.cooldownUntil,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatbotState({
    required this.messages,
    required this.isLoading,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatbotNotifier extends Notifier<ChatbotState> {
  ChatSession? _chatSession;
  int _currentChatModelIndex = 0;
  static const _availableModels = ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-flash', 'gemini-1.5-pro'];
  String _lastContextData = 'No hay datos de inventario disponibles.';

  @override
  ChatbotState build() {
    return ChatbotState(
      messages: [
        ChatMessage(
          text: '¡Hola! Soy QuickBot 🤖, tu asistente inteligente de QuickInvent. ¿En qué te puedo ayudar hoy?',
          isUser: false,
        ),
      ],
      isLoading: false,
    );
  }

  void _initSession({bool forceRecreate = false}) {
    if (_chatSession == null || forceRecreate) {
      final productsAsync = ref.read(productsProvider);
      
      productsAsync.whenData((products) {
        if (products.isEmpty) {
          _lastContextData = 'El inventario está vacío.';
        } else {
          _lastContextData = products.map((p) => 
            '- ${p.name} | Precio: \$${p.price} | Stock: ${p.stockQuantity} | Tiene Foto: ${p.imageUrl != null && p.imageUrl!.isNotEmpty ? "Sí" : "No"}'
          ).join('\n');
        }
      });

      final gemini = ref.read(geminiServiceProvider);
      _chatSession = gemini.startChatSession(
        inventoryContext: _lastContextData,
        modelName: _availableModels[_currentChatModelIndex],
        history: forceRecreate && _chatSession != null ? _chatSession!.history.toList() : null,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _initSession();

    // Agregar el mensaje del usuario
    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    bool success = false;
    String? finalErrorText;
    DateTime? finalCooldown;

    while (!success && _currentChatModelIndex < _availableModels.length) {
      try {
        var response = await _chatSession!.sendMessage(Content.text(text));
        
        // Manejar múltiples llamadas a funciones si es necesario
        while (response.functionCalls.isNotEmpty) {
          final calls = response.functionCalls.toList();
          final functionResponses = <FunctionResponse>[];

          for (final call in calls) {
            if (call.name == 'asignar_foto_producto') {
              final productId = call.args['productId'] as String;
              final productName = call.args['productName'] as String;
              
              debugPrint('Gemini solicitó foto para: $productName (ID: $productId)');
              
              try {
                // 1. Descargar imagen genérica de LoremFlickr basada en el nombre
                final keyword = Uri.encodeComponent(productName);
                final imageUrl = 'https://loremflickr.com/800/800/$keyword';
                final httpResponse = await http.get(Uri.parse(imageUrl));
                
                if (httpResponse.statusCode == 200) {
                  // 2. Convertir a XFile
                  final bytes = httpResponse.bodyBytes;
                  final fileExt = 'jpg';
                  final fileName = '${DateTime.now().millisecondsSinceEpoch}_${productName.replaceAll(RegExp(r'[^\w\s]+'), '')}.$fileExt';
                  final xFile = XFile.fromData(bytes, name: fileName, mimeType: 'image/jpeg');
                  
                  // 3. Subir a Supabase
                  final repo = ref.read(productsRepositoryProvider);
                  final uploadedUrl = await repo.uploadProductImage(productName, xFile);
                  
                  if (uploadedUrl != null) {
                    // 4. Actualizar el producto en la BD
                    final products = await ref.read(productsProvider.future);
                    final product = products.firstWhere((p) => p.id.toString() == productId);
                    
                    await repo.updateProduct(
                      productId: productId,
                      name: product.name,
                      price: product.price,
                      stockQuantity: product.stockQuantity,
                      minStock: product.minStock,
                      isActive: product.isActive,
                      barcode: product.barcode,
                      categoryId: product.categoryId?.toString(),
                      imageUrl: uploadedUrl,
                      costPrice: product.costPrice,
                    );
                    
                    // Forzar la recarga del inventario
                    ref.invalidate(productsProvider);
                    
                    functionResponses.add(FunctionResponse(
                      call.name, 
                      {'status': 'success', 'message': 'Foto descargada, subida y asignada con éxito al producto.', 'imageUrl': uploadedUrl}
                    ));
                  } else {
                    functionResponses.add(FunctionResponse(
                      call.name, 
                      {'status': 'error', 'message': 'Fallo al subir la imagen a Supabase.'}
                    ));
                  }
                } else {
                  functionResponses.add(FunctionResponse(
                    call.name, 
                    {'status': 'error', 'message': 'No se encontró imagen en internet para este producto.'}
                  ));
                }
              } catch (e) {
                debugPrint('Error en asignar_foto_producto: $e');
                functionResponses.add(FunctionResponse(
                  call.name, 
                  {'status': 'error', 'message': 'Error interno: $e'}
                ));
              }
            } else {
              // Función desconocida
              functionResponses.add(FunctionResponse(
                call.name, 
                {'status': 'error', 'message': 'Función no implementada.'}
              ));
            }
          }
          
          // Enviar resultados de vuelta a Gemini para que continúe
          response = await _chatSession!.sendMessage(Content.functionResponses(functionResponses));
        }
        
        final botMsg = ChatMessage(
          text: response.text ?? 'Proceso completado.',
          isUser: false,
        );
        
        state = state.copyWith(
          messages: [...state.messages, botMsg],
          isLoading: false,
        );
        success = true;
      } catch (e) {
        debugPrint('Error en QuickBot (modelo ${_availableModels[_currentChatModelIndex]}): $e');
        final errorStr = e.toString();
        
        if (errorStr.contains('Quota exceeded') || errorStr.contains('429')) {
          _currentChatModelIndex++;
          if (_currentChatModelIndex < _availableModels.length) {
            debugPrint('Intentando con el siguiente modelo: ${_availableModels[_currentChatModelIndex]}');
            _initSession(forceRecreate: true);
            continue;
          } else {
            // Intentar extraer los segundos para mostrar un mejor mensaje
            final retryMatch = RegExp(r'retry in ([\d\.]+)(m?)s').firstMatch(errorStr);
            if (retryMatch != null) {
              final value = double.tryParse(retryMatch.group(1) ?? '60') ?? 60.0;
              final isMs = retryMatch.group(2) == 'm';
              final seconds = isMs ? (value / 1000).ceil() : value.ceil();
              
              finalCooldown = DateTime.now().add(Duration(seconds: seconds > 0 ? seconds : 1));
              finalErrorText = 'Has excedido el límite de velocidad en todos los modelos. ⏱️ Por favor, espera antes de enviar otro mensaje.';
            } else {
              finalCooldown = DateTime.now().add(const Duration(seconds: 60));
              finalErrorText = 'Has excedido la cuota gratuita en todos los modelos disponibles. ⏱️ Por favor, espera para que se reinicie el contador antes de intentar de nuevo.';
            }
            break;
          }
        } else {
          finalErrorText = 'Hubo un error al intentar conectarme. Verifica tu conexión a internet o tu API Key.';
          break;
        }
      }
    }

    if (!success && finalErrorText != null) {
      final errorMsg = ChatMessage(
        text: finalErrorText,
        isUser: false,
        isError: true,
        cooldownUntil: finalCooldown,
      );
      
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }

  void clearHistory() {
    _chatSession = null;
    state = ChatbotState(
      messages: [
        ChatMessage(
          text: 'Historial borrado. ¡Hola de nuevo! ¿Qué necesitas?',
          isUser: false,
        ),
      ],
      isLoading: false,
    );
  }
}

final chatbotProvider = NotifierProvider<ChatbotNotifier, ChatbotState>(() {
  return ChatbotNotifier();
});

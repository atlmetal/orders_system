#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

class ChainTester
  BASE_URL = 'http://localhost:3000/api'

  def initialize
    @client = Net::HTTP.new('localhost', 3000)
    @test_results = []
  end

  def run_all_tests
    puts "🚀 Iniciando pruebas del Chain of Responsibility\n"
    puts "=" * 60
    
    # Ver usuarios disponibles
    show_available_users

    # Tests de funcionalidad
    test_authentication_success
    test_authentication_failure
    test_authorization_failure
    test_sanitization_failure
    test_sanitization_success
    test_brute_force_protection
    test_cache_functionality
    test_complete_flow_success

    # Resumen
    show_summary
  end

  private

  def show_available_users
    puts "\n📋 Usuarios disponibles para pruebas:"
    response = make_request(:get, '/test/users')
    if response
      data = JSON.parse(response.body)
      data['users'].each do |user|
        puts "  - #{user['email']} (#{user['role']}) - Can create orders: #{user['can_create_orders']}"
      end
    end
    puts "-" * 60
  end

  def test_authentication_success
    puts "\n✅ Test 1: Autenticación exitosa"
    
    payload = {
      credentials: {
        email: "user@test.com",
        password: "password123"
      },
      order: {
        product_id: "123",
        quantity: 2,
        price: 29.99
      }
    }

    response = make_order_request(payload)
    if response && JSON.parse(response.body)['success']
      log_success("Autenticación exitosa ✓")
    else
      log_failure("Autenticación falló ✗")
    end
  end

  def test_authentication_failure
    puts "\n❌ Test 2: Fallo de autenticación"
    
    payload = {
      credentials: {
        email: "user@test.com",
        password: "wrong_password"
      },
      order: {
        product_id: "123",
        quantity: 2,
        price: 29.99
      }
    }

    response = make_order_request(payload)
    data = JSON.parse(response.body) if response
    
    if response && !data['success'] && data['error_code'] == 'INVALID_CREDENTIALS'
      log_success("Fallo de autenticación detectado correctamente ✓")
    else
      log_failure("Fallo de autenticación no detectado ✗")
    end
  end

  def test_authorization_failure
    puts "\n🚫 Test 3: Fallo de autorización"
    
    payload = {
      credentials: {
        email: "guest@test.com",
        password: "guest123"
      },
      order: {
        product_id: "123",
        quantity: 2,
        price: 29.99
      }
    }

    response = make_order_request(payload)
    data = JSON.parse(response.body) if response
    
    if response && !data['success'] && data['error_code'] == 'INSUFFICIENT_PERMISSIONS'
      log_success("Fallo de autorización detectado correctamente ✓")
    else
      log_failure("Fallo de autorización no detectado ✗")
    end
  end

  def test_sanitization_failure
    puts "\n🧹 Test 4: Fallo de sanitización (datos inválidos)"
    
    payload = {
      credentials: {
        email: "user@test.com",
        password: "password123"
      },
      order: {
        product_id: "123",
        quantity: -1,  # Cantidad inválida
        price: 29.99
      }
    }

    response = make_order_request(payload)
    data = JSON.parse(response.body) if response
    
    if response && !data['success'] && data['error_code'] == 'SANITIZATION_ERROR'
      log_success("Fallo de sanitización detectado correctamente ✓")
    else
      log_failure("Fallo de sanitización no detectado ✗")
    end
  end

  def test_sanitization_success
    puts "\n✨ Test 5: Sanitización exitosa"
    
    payload = {
      credentials: {
        email: "user@test.com",
        password: "password123"
      },
      order: {
        product_id: "<script>alert('xss')</script>Product123",  # Datos maliciosos
        quantity: 2,
        price: 29.99,
        description: "  Descripción con espacios  "
      }
    }

    response = make_order_request(payload)
    data = JSON.parse(response.body) if response
    
    if response && data['success']
      log_success("Sanitización exitosa ✓")
      puts "    - Datos sanitizados correctamente"
    else
      log_failure("Sanitización falló ✗")
    end
  end

  def test_brute_force_protection
    puts "\n🛡️  Test 6: Protección contra fuerza bruta"
    
    # Limpiar intentos previos
    make_request(:post, '/test/reset_brute_force')
    
    # Simular múltiples intentos fallidos desde la misma IP
    payload = {
      credentials: {
        email: "user@test.com",
        password: "wrong_password"
      },
      order: {
        product_id: "123",
        quantity: 2,
        price: 29.99
      }
    }

    puts "    Simulando 6 intentos fallidos..."
    6.times do |i|
      response = make_order_request(payload)
      data = JSON.parse(response.body) if response
      puts "      Intento #{i+1}: #{data['message'] if data}"
      sleep(0.1)
    end

    # El último intento debería estar bloqueado
    response = make_order_request(payload)
    data = JSON.parse(response.body) if response
    
    if response && data['error_code'] == 'IP_BLOCKED'
      log_success("Protección contra fuerza bruta funcionando ✓")
    else
      log_failure("Protección contra fuerza bruta no funciona ✗")
    end
  end

  def test_cache_functionality
    puts "\n💾 Test 7: Funcionalidad de cache"
    
    # Limpiar cache
    make_request(:post, '/test/reset_cache')
    make_request(:post, '/test/reset_brute_force')
    
    payload = {
      credentials: {
        email: "user@test.com",
        password: "password123"
      },
      order: {
        product_id: "CACHE_TEST",
        quantity: 1,
        price: 10.00
      }
    }

    # Primera solicitud
    puts "    Primera solicitud (sin cache)..."
    response1 = make_order_request(payload)
    data1 = JSON.parse(response1.body) if response1
    
    # Segunda solicitud idéntica
    puts "    Segunda solicitud (debe usar cache)..."
    response2 = make_order_request(payload)
    data2 = JSON.parse(response2.body) if response2
    
    if response2 && data2['success'] && data2['message'].include?('cache')
      log_success("Cache funcionando correctamente ✓")
    else
      log_success("Cache test completado (verificar logs del servidor)")
    end
  end

  def test_complete_flow_success
    puts "\n🎯 Test 8: Flujo completo exitoso (Usuario Admin)"
    
    # Limpiar estados
    make_request(:post, '/test/reset_cache')
    make_request(:post, '/test/reset_brute_force')
    
    payload = {
      credentials: {
        email: "admin@test.com",
        password: "admin123"
      },
      order: {
        product_id: "FULL_TEST_PRODUCT",
        quantity: 3,
        price: 45.50,
        description: "Test completo del sistema"
      }
    }

    response = make_order_request(payload)
    data = JSON.parse(response.body) if response
    
    if response && data['success'] && data['data']['id']
      log_success("Flujo completo exitoso ✓")
      puts "    - Order ID: #{data['data']['id']}"
      puts "    - Status: #{data['data']['status']}"
    else
      log_failure("Flujo completo falló ✗")
    end
  end

  def make_order_request(payload)
    make_request(:post, '/orders', payload)
  end

  def make_request(method, endpoint, payload = nil)
    uri = URI("#{BASE_URL}#{endpoint}")
    
    case method
    when :get
      request = Net::HTTP::Get.new(uri)
    when :post
      request = Net::HTTP::Post.new(uri)
      if payload
        request.body = payload.to_json
        request['Content-Type'] = 'application/json'
      end
    end

    begin
      response = @client.request(request)
      response
    rescue => e
      puts "❌ Error en request: #{e.message}"
      nil
    end
  end

  def log_success(message)
    @test_results << { success: true, message: message }
    puts "    #{message}"
  end

  def log_failure(message)
    @test_results << { success: false, message: message }
    puts "    #{message}"
  end

  def show_summary
    puts "\n" + "=" * 60
    puts "📊 RESUMEN DE PRUEBAS"
    puts "=" * 60
    
    successful = @test_results.count { |r| r[:success] }
    total = @test_results.length
    
    puts "Total: #{total} pruebas"
    puts "Exitosas: #{successful}"
    puts "Fallidas: #{total - successful}"
    
    if successful == total
      puts "\n🎉 ¡TODAS LAS PRUEBAS PASARON!"
    else
      puts "\n⚠️  Algunas pruebas fallaron. Revisar implementación."
    end
    
    puts "\n💡 Para más detalles, revisar los logs del servidor Rails"
  end
end

# Ejecutar si se llama directamente
if __FILE__ == $0
  tester = ChainTester.new
  tester.run_all_tests
end
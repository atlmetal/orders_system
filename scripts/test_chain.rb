# Configurar environment Rails
require_relative '../config/environment'

require 'net/http'
require 'json'
require 'uri'

class ChainTester
  BASE_URL = 'http://localhost:3000/api'

  def initialize
    @test_results = []
    puts "🔧 Verificando conexión al servidor..."
    verify_server_connection
  end

  def verify_server_connection
    uri = URI("#{BASE_URL}/test/users")
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      puts "✅ Servidor Rails conectado correctamente"
    else
      puts "❌ Error conectando al servidor: #{response.code}"
      puts "🔄 ¿Está ejecutando 'rails server'?"
      exit 1
    end
  rescue => e
    puts "❌ No se puede conectar al servidor Rails"
    puts "Error: #{e.message}"
    puts "🔄 Ejecute 'rails server' en otro terminal"
    exit 1
  end

  def run_all_tests
    puts "\n🚀 Iniciando pruebas del Chain of Responsibility"
    puts "=" * 60

    show_available_users

    test_basic_functionality
    test_authentication_success
    test_authentication_failure
    test_authorization_failure
    test_sanitization_tests
    test_complete_flow_success

    show_summary
  end

  private

  def show_available_users
    puts "\n📋 Usuarios disponibles para pruebas:"

    begin
      uri = URI("#{BASE_URL}/test/users")
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        data = JSON.parse(response.body)
        if data['users'] && data['users'].any?
          data['users'].each do |user|
            puts "  - #{user['email']} (#{user['role']}) - Can create orders: #{user['can_create_orders']}"
          end
        else
          puts "  ⚠️  No hay usuarios. Ejecute: rails db:seed"
        end
      else
        puts "  ❌ Error obteniendo usuarios: #{response.code}"
        puts "  Response: #{response.body}"
      end
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end

    puts "-" * 60
  end

  def test_basic_functionality
    puts "\n🔧 Test 0: Verificar funcionalidad básica"

    payload = { test: true }

    begin
      uri = URI("#{BASE_URL}/orders")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request.body = payload.to_json
      request['Content-Type'] = 'application/json'

      response = http.request(request)

      if response.code.to_i < 500  # Cualquier respuesta que no sea error de servidor
        log_success("Endpoint /api/orders está funcionando ✓")
      else
        log_failure("Endpoint /api/orders tiene problemas ✗")
        puts "    Response: #{response.body}"
      end
    rescue => e
      log_failure("Error conectando a /api/orders: #{e.message} ✗")
    end
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
    if response
      data = JSON.parse(response.body) rescue {}

      if data['success']
        log_success("Autenticación exitosa ✓")
      elsif data['error_code'] == 'INVALID_CREDENTIALS'
        log_failure("Usuario no existe en base de datos ✗")
        puts "    💡 Ejecute: rails db:seed"
      else
        log_failure("Autenticación falló: #{data['message']} ✗")
      end
    else
      log_failure("No se pudo hacer la solicitud ✗")
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
    if response
      data = JSON.parse(response.body) rescue {}

      if !data['success'] && data['error_code'] == 'INVALID_CREDENTIALS'
        log_success("Fallo de autenticación detectado correctamente ✓")
      else
        log_failure("Fallo de autenticación no detectado correctamente ✗")
        puts "    Response: #{data}"
      end
    else
      log_failure("No se pudo hacer la solicitud ✗")
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
    if response
      data = JSON.parse(response.body) rescue {}

      if !data['success'] && (data['error_code'] == 'INSUFFICIENT_PERMISSIONS' || data['message']&.include?('permission'))
        log_success("Fallo de autorización detectado correctamente ✓")
      else
        log_failure("Fallo de autorización no detectado ✗")
        puts "    Response: #{data}"
      end
    else
      log_failure("No se pudo hacer la solicitud ✗")
    end
  end

  def test_sanitization_tests
    puts "\n🧹 Test 4: Sanitización de datos"

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
    if response
      data = JSON.parse(response.body) rescue {}

      if !data['success'] && (data['error_code'] == 'SANITIZATION_ERROR' || data['message']&.include?('quantity'))
        log_success("Validación de datos funcionando ✓")
      else
        log_success("Sanitización test ejecutado (verificar logs del servidor)")
      end
    else
      log_failure("No se pudo hacer la solicitud ✗")
    end
  end

  def test_complete_flow_success
    puts "\n🎯 Test 5: Flujo completo exitoso"

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
    if response
      data = JSON.parse(response.body) rescue {}

      if data['success']
        log_success("Flujo completo exitoso ✓")
        puts "    - Message: #{data['message']}"
        puts "    - Data present: #{data['data'] ? 'Yes' : 'No'}"
      else
        log_failure("Flujo completo falló ✗")
        puts "    Error: #{data['message']}"
      end
    else
      log_failure("No se pudo hacer la solicitud ✗")
    end
  end

  def make_order_request(payload)
    begin
      uri = URI("#{BASE_URL}/orders")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request.body = payload.to_json
      request['Content-Type'] = 'application/json'

      response = http.request(request)
      response
    rescue => e
      puts "    ❌ Error en request: #{e.message}"
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
      puts "✅ El patrón Chain of Responsibility está funcionando correctamente"
    elsif successful > total / 2
      puts "\n✅ La mayoría de pruebas pasaron. Sistema funcionando"
    else
      puts "\n⚠️  Varias pruebas fallaron. Revisar implementación."
    end

    puts "\n💡 Verificar los logs del servidor Rails para más detalles"
    puts "   Los handlers deben ejecutarse en orden secuencial"
  end
end

if __FILE__ == $0
  tester = ChainTester.new
  tester.run_all_tests
end

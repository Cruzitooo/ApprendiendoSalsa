//
//  RegistrarPagoEfectivoView.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 26/4/25.
//

import SwiftUI
import SwiftData

struct RegistrarPagoEfectivoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var alumno: Alumno
    
    @State private var importe: String = ""
    @State private var concepto: String = ""
    @State private var mostrarAlerta = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Importe")) {
                    TextField("Introduce el importe (€)", text: $importe)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Concepto")) {
                    TextField("Opcional: Concepto del pago", text: $concepto)
                }
                
                Section {
                    Button(action: guardarPago) {
                        Text("Guardar pago")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Pago en efectivo")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                        Text("Atrás")
                    }
                }
            }
            .alert("Importe inválido", isPresented: $mostrarAlerta) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Introduce un importe válido mayor que 0.")
            }
        }
    }
    
    private func guardarPago() {
        guard let importeDouble = Double(importe.replacingOccurrences(of: ",", with: ".")), importeDouble > 0 else {
            mostrarAlerta = true
            return
        }
        
        let nuevoPago = PagoAppEfectivo(
            id: UUID(),
            alumnoNombre: alumno.nombre,
            importe: importeDouble,
            estado: "pagado", // 👈🏻 Primero el estado
            concepto: concepto.isEmpty ? "Pago en efectivo" : concepto, // 👈🏻 Luego el concepto
            claseNombre: alumno.categoria,
            fechaCreacion: Date()
        )

        modelContext.insert(nuevoPago)
        
        do {
            try modelContext.save()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error al guardar el pago: \(error)")
        }
    }
}

#Preview {
    let alumnoEjemplo = Alumno(nombre: "Ejemplo", email: "ejemplo@email.com", categoria: "Clase Lunes")
    return RegistrarPagoEfectivoView(alumno: alumnoEjemplo)
}

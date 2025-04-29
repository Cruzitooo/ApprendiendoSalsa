//
//  AsistenciaAlumnoView.swift
//  AprendiendoSalsa
//
//  Creado por Christian Cruz
//

import SwiftUI
import SwiftData

struct AsistenciaAlumnoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var asistencias: [Asistencia]

    var alumno: Alumno
    var categoria: ClaseCategoria
    var pagos: [PagoLocal]
    var mesSeleccionado: Int
    var anioSeleccionado: Int

    var body: some View {
        List {
            Section(header: Text("Asistencia – \(alumno.nombre)")) {
                ForEach(fechasDelMes(), id: \.self) { fecha in
                    HStack {
                        Text(formatearFecha(fecha))
                        Spacer()

                        if let asistencia = asistenciaPara(fecha: fecha) {
                            Image(systemName: asistencia.asistio ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(asistencia.asistio ? .green : .red)
                                .onTapGesture {
                                    toggleAsistencia(fecha: fecha, asistio: !asistencia.asistio)
                                }
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    toggleAsistencia(fecha: fecha, asistio: false)
                                }
                        }
                    }
                }
            }

            Section(header: Text("Pagos")) {
                Text(descripcionPago())
            }
        }
        .navigationTitle("Asistencia")
    }

    // ✅ Calcula fechas reales del mes
    private func fechasDelMes() -> [Date] {
        var fechas: [Date] = []
        let calendar = Calendar.current
        let componentes = DateComponents(year: anioSeleccionado, month: mesSeleccionado)
        let rango = calendar.range(of: .day, in: .month, for: calendar.date(from: componentes)!)!

        for dia in rango {
            if let fecha = calendar.date(from: DateComponents(year: anioSeleccionado, month: mesSeleccionado, day: dia)),
               calendar.component(.weekday, from: fecha) == diaDeClase(categoria.nombre) {
                fechas.append(fecha)
            }
        }

        return fechas
    }

    // ✅ Busca asistencia existente por fecha
    private func asistenciaPara(fecha: Date) -> Asistencia? {
        asistencias.first(where: {
            $0.alumnoID == alumno.id &&
            Calendar.current.isDate($0.fecha, inSameDayAs: fecha) &&
            $0.categoriaID == categoria.id
        })
    }

    // ✅ Alterna o crea asistencia
    private func toggleAsistencia(fecha: Date, asistio: Bool) {
        if let existente = asistenciaPara(fecha: fecha) {
            existente.asistio = asistio
        } else {
            let nueva = Asistencia(fecha: fecha, alumnoID: alumno.id, categoriaID: categoria.id, asistio: asistio)
            modelContext.insert(nueva)
        }

        try? modelContext.save()
    }

    // ✅ Formato de fecha
    private func formatearFecha(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: fecha)
    }

    // ✅ Día de clase según nombre de categoría
    private func diaDeClase(_ nombreCategoria: String) -> Int {
        if nombreCategoria.contains("Lunes") { return 2 }
        if nombreCategoria.contains("Martes") { return 3 }
        if nombreCategoria.contains("Miércoles") { return 4 }
        if nombreCategoria.contains("Jueves") { return 5 }
        if nombreCategoria.contains("Viernes") { return 6 }
        return 1 // Domingo por defecto
    }

    // ✅ Ejemplo simple de descripción de pago
    private func descripcionPago() -> String {
        switch cantidadPagada() {
        case 45 where diaDentroRango(): return "Pago mensual (promo)"
        case 60 where diaDentroRango(): return "Pago mensual (5 semanas)"
        case 30: return "Pago mínimo"
        default: return "ninguno"
        }
    }

    private func cantidadPagada() -> Double {
        pagos
            .filter { $0.alumnoID == alumno.id }
            .filter { Calendar.current.component(.month, from: $0.fecha) == mesSeleccionado }
            .reduce(0) { $0 + $1.importe }
    }

    private func diaDentroRango() -> Bool {
        let hoy = Calendar.current.component(.day, from: Date())
        return hoy >= 1 && hoy <= 5
    }
}

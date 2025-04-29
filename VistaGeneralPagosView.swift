//
//  VistaGeneralPagosView.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 25/4/25.
//

import SwiftUI
import Charts

struct VistaGeneralPagosView: View {
    @State private var mesSeleccionado = Calendar.current.component(.month, from: Date())
    @State private var anioSeleccionado = Calendar.current.component(.year, from: Date())
    @State private var ocultarMontos = false

    // Simulación de datos
    let categorias: [ClaseCategoria] = [
        ClaseCategoria(nombre: "Clase Lunes"),
        ClaseCategoria(nombre: "Taller Musicalidad"),
        ClaseCategoria(nombre: "Intensivo Abril")
    ]

    let pagosPorCategoria: [String: (pagados: Int, total: Int, monto: Double)] = [
        "Clase Lunes": (3, 5, 135),
        "Taller Musicalidad": (2, 4, 90),
        "Intensivo Abril": (0, 3, 0)
    ]

    let resumenGeneral: (stripe: Double, efectivo: Double) = (320, 90)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Título y selector de mes
                    HStack {
                        Text("PAGOS")
                            .font(.largeTitle.bold())
                        Spacer()
                        Button("\(nombreMes(mesSeleccionado)) \(anioSeleccionado)") {
                            // En el futuro: selector visual
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    // Tarjetas por categoría
                    ForEach(categorias, id: \.nombre) { categoria in
                        if let datos = pagosPorCategoria[categoria.nombre] {
                            NavigationLink(destination:
                                PagosCategoriaView(
                                    categoria: categoria,
                                    alumnos: [] // Se actualizará con datos reales
                                )
                            ) {
                                tarjetaCategoria(
                                    nombre: categoria.nombre,
                                    monto: datos.monto,
                                    pagados: datos.pagados,
                                    total: datos.total
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Tarjeta GENERAL
                    tarjetaGeneral(
                        monto: resumenGeneral.stripe + resumenGeneral.efectivo,
                        pagados: pagosPorCategoria.values.map { $0.pagados }.reduce(0, +),
                        total: pagosPorCategoria.values.map { $0.total }.reduce(0, +),
                        stripe: resumenGeneral.stripe,
                        efectivo: resumenGeneral.efectivo
                    )

                    // Gráfico circular
                    graficoCircularResumen()

                    // Nuevo botón: Historial de pagos Stripe
                    NavigationLink(destination: HistorialPagosStripeView()) {
                        Text("Ver historial de pagos Stripe")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .background(
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? .black : .systemGray6
                }).ignoresSafeArea()
            )
        }
    }

    func tarjetaCategoria(nombre: String, monto: Double, pagados: Int, total: Int) -> some View {
        let porcentaje = Double(pagados) / Double(total)
        let colorBorde: Color = porcentaje == 1 ? .green : (porcentaje == 0 ? .red : .yellow)

        return VStack(alignment: .leading, spacing: 10) {
            Text(nombre)
                .font(.headline)
            Text(ocultarMontos ? "*** €" : "\(Int(monto)) €")
                .font(.title2.monospacedDigit())
                .bold()
                .onTapGesture { ocultarMontos.toggle() }

            Text("\(pagados) de \(total) han pagado")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading) {
                Text("Alumnos (demo)")
                    .font(.caption)
                    .foregroundColor(.gray)

                NavigationLink(destination: PagoAlumnoView(alumnoNombre: "Laura González", alumno: Alumno(nombre: "Laura González"))) {
                    Text("➡️ Laura González")
                }

                NavigationLink(destination: PagoAlumnoView(alumnoNombre: "Carlos Ramírez", alumno: Alumno(nombre: "Carlos Ramírez"))) {
                    Text("➡️ Carlos Ramírez")
                }
            }
            .font(.footnote)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor {
                    $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
                }))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorBorde, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }

    func tarjetaGeneral(monto: Double, pagados: Int, total: Int, stripe: Double, efectivo: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📦 General")
                .font(.headline)
            Text(ocultarMontos ? "*** €" : "\(Int(monto)) €")
                .font(.title2.monospacedDigit())
                .bold()
                .onTapGesture { ocultarMontos.toggle() }

            Text("\(pagados) de \(total) alumnos pagaron")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !ocultarMontos {
                Text("💳 Stripe: \(Int(stripe)) € | 💶 Efectivo: \(Int(efectivo)) €")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor {
                    $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
                }))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }

    func graficoCircularResumen() -> some View {
        let totalPagos = pagosPorCategoria.values.map { $0.total }.reduce(0, +)
        let totalPagados = pagosPorCategoria.values.map { $0.pagados }.reduce(0, +)
        let pendiente = max(0, totalPagos - totalPagados)

        let datos: [(String, Double)] = [
            ("Pagado", Double(totalPagados)),
            ("Pendiente", Double(pendiente))
        ]

        return VStack(alignment: .leading) {
            Text("Resumen mensual")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(datos, id: \.0) { segmento in
                    SectorMark(
                        angle: .value("Cantidad", segmento.1),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Estado", segmento.0))
                }
            }
            .frame(height: 200)
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor {
                    $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
                }))
        )
        .padding(.horizontal)
    }

    func nombreMes(_ numero: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.monthSymbols[numero - 1].capitalized
    }
}

#Preview {
    VistaGeneralPagosView()
}

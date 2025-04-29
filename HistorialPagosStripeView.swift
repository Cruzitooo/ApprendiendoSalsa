import SwiftUI
import SwiftData

struct HistorialPagosStripeView: View {
    @Query(sort: [SortDescriptor(\PagoAppStripe.fechaCreacion, order: .reverse)]) var pagosStripe: [PagoAppStripe]
    @Query(sort: [SortDescriptor(\PagoAppEfectivo.fechaCreacion, order: .reverse)]) var pagosEfectivo: [PagoAppEfectivo]
    @Query var categorias: [ClaseCategoria]

    @State private var mesSeleccionado = Calendar.current.component(.month, from: Date())
    @State private var anioSeleccionado = Calendar.current.component(.year, from: Date())
    @State private var claseSeleccionada: String = "Todas"
    @State private var tipoPagoSeleccionado: TipoFiltroPago = .todos

    @State private var mostrarSelectorFecha = false

    var clasesDisponibles: [String] {
        ["Todas"] + categorias.map { $0.nombre }.sorted()
    }

    var pagosCombinadosFiltrados: [PagoUnificado] {
        let pagosStripeFiltrados = pagosStripe.filter { pago in
            filtrarPago(pago.fechaCreacion, claseNombre: pago.claseNombre)
        }.map { pago in
            PagoUnificado(
                id: pago.id,
                alumnoNombre: pago.alumnoNombre,
                importe: pago.importe,
                estado: pago.estado,
                concepto: pago.concepto,
                claseNombre: pago.claseNombre,
                fechaCreacion: pago.fechaCreacion,
                tipo: .stripe
            )
        }

        let pagosEfectivoFiltrados = pagosEfectivo.filter { pago in
            filtrarPago(pago.fechaCreacion, claseNombre: pago.claseNombre)
        }.map { pago in
            PagoUnificado(
                id: pago.id,
                alumnoNombre: pago.alumnoNombre,
                importe: pago.importe,
                estado: pago.estado,
                concepto: pago.concepto,
                claseNombre: pago.claseNombre,
                fechaCreacion: pago.fechaCreacion,
                tipo: .efectivo
            )
        }

        var combinados = [PagoUnificado]()

        switch tipoPagoSeleccionado {
        case .todos:
            combinados = pagosStripeFiltrados + pagosEfectivoFiltrados
        case .stripe:
            combinados = pagosStripeFiltrados
        case .efectivo:
            combinados = pagosEfectivoFiltrados
        }

        return combinados.sorted { $0.fechaCreacion > $1.fechaCreacion }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    filtrosSection

                    if pagosCombinadosFiltrados.isEmpty {
                        Text("No hay pagos registrados.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        pagosSection
                    }
                }
                .padding(.top)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Historial Pagos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportarPagos()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $mostrarSelectorFecha) {
                selectorFecha
            }
        }
    }

    var filtrosSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button("\(nombreMes(mesSeleccionado)) \(anioSeleccionado)") {
                    mostrarSelectorFecha.toggle()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)

                Spacer()

                Picker("Clase", selection: $claseSeleccionada) {
                    ForEach(clasesDisponibles, id: \ .self) { clase in
                        Text(clase)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }

            HStack {
                Text("Filtrar por:")
                    .font(.subheadline)
                Picker("Tipo de pago", selection: $tipoPagoSeleccionado) {
                    ForEach(TipoFiltroPago.allCases, id: \ .self) { tipo in
                        Text(tipo.nombreVisible)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            resumenGeneral
        }
        .padding(.horizontal)
    }

    var pagosSection: some View {
        VStack(spacing: 0) {
            ForEach(pagosCombinadosFiltrados, id: \ .id) { pago in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(colorEstado(pago.estado))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pago.alumnoNombre)
                            .font(.headline)
                        Text(textoImporteEstadoTipo(pago: pago))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(pago.concepto) • \(formatearFecha(pago.fechaCreacion))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(Int(pago.importe)) €")
                            .font(.headline)
                        if tieneIncidencia(pago) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(.vertical, 8)

                Divider()
                    .padding(.leading, 30)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    var resumenGeneral: some View {
        let stripe = pagosCombinadosFiltrados.filter { $0.tipo == .stripe }.map(\.importe).reduce(0, +)
        let efectivo = pagosCombinadosFiltrados.filter { $0.tipo == .efectivo }.map(\.importe).reduce(0, +)
        let total = stripe + efectivo

        return HStack {
            Text("💳 \(Int(stripe)) €")
            Spacer()
            Text("💵 \(Int(efectivo)) €")
            Spacer()
            Text("🧾 \(Int(total)) €")
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.vertical, 4)
    }

    var selectorFecha: some View {
        VStack {
            Spacer(minLength: 20)

            VStack {
                Text("Selecciona mes y año")
                    .font(.headline)
                    .padding()

                HStack {
                    Picker("Mes", selection: $mesSeleccionado) {
                        ForEach(1...12, id: \ .self) { mes in
                            Text(nombreMes(mes)).tag(mes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 150)

                    Picker("Año", selection: $anioSeleccionado) {
                        let anioActual = Calendar.current.component(.year, from: Date())
                        ForEach((anioActual-5)...(anioActual+1), id: \ .self) { anio in
                            Text("\(anio)").tag(anio)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }

                Button("Aplicar") {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    mostrarSelectorFecha = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal, 30)

            Spacer()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: mostrarSelectorFecha)
    }

    func filtrarPago(_ fecha: Date, claseNombre: String?) -> Bool {
        let calendar = Calendar.current
        let componentes = calendar.dateComponents([.month, .year], from: fecha)
        let coincideMes = (componentes.month == mesSeleccionado && componentes.year == anioSeleccionado)
        let coincideClase = (claseSeleccionada == "Todas" || claseNombre == claseSeleccionada)
        return coincideMes && coincideClase
    }

    func nombreMes(_ numero: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.monthSymbols[numero - 1].capitalized
    }

    func formatearFecha(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: fecha)
    }

    func textoImporteEstadoTipo(pago: PagoUnificado) -> String {
        let importe = String(format: "%.2f", pago.importe)
        let estado = pago.estado.capitalized
        let icono = pago.tipo == .stripe ? "💳" : "💵"
        return "\(importe) € • \(estado) \(icono)"
    }

    func colorEstado(_ estado: String) -> Color {
        switch estado.lowercased() {
        case "pagado":
            return .green
        case "pendiente":
            return .orange
        default:
            return .red
        }
    }

    func tieneIncidencia(_ pago: PagoUnificado) -> Bool {
        let day = Calendar.current.component(.day, from: pago.fechaCreacion)
        let pagoAtrasado = day > 5
        let pagoInsuficiente = pago.importe < 30
        return pagoAtrasado || pagoInsuficiente
    }

    func exportarPagos() {
        print("Exportar pagos aún no implementado.")
    }
}

struct PagoUnificado {
    var id: UUID
    var alumnoNombre: String
    var importe: Double
    var estado: String
    var concepto: String
    var claseNombre: String?
    var fechaCreacion: Date
    var tipo: TipoPago
}

enum TipoPago {
    case stripe
    case efectivo
}

enum TipoFiltroPago: String, CaseIterable {
    case todos, stripe, efectivo

    var nombreVisible: String {
        switch self {
        case .todos: "Todos"
        case .stripe: "Stripe"
        case .efectivo: "Efectivo"
        }
    }
}

#Preview {
    HistorialPagosStripeView()
}

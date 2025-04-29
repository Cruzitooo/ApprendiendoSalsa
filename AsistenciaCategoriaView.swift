import SwiftUI
import SwiftData
import AudioToolbox

struct AsistenciaCategoriaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var alumnos: [Alumno]

    var categoria: ClaseCategoria
    var pagos: [PagoLocal]

    // --- Estados para la UI ---
    @State private var asistenciasManual: [Asistencia] = []
    @State private var mesSeleccionado: Int
    @State private var anioSeleccionado: Int
    @State private var fechaSeleccionada: Date?
    @State private var mostrarSoloActivos: Bool
    @State private var mostrarPickerFecha: Bool
    @State private var textoBusqueda: String

    // --- Petición 2: Persistencia Fecha (Manual con UserDefaults) ---
    // @State para el valor en memoria
    @State private var ultimaFechaSeleccionadaIntervalState: TimeInterval?
    // Clave para guardar/leer en UserDefaults
    private let userDefaultsKey: String

    // MARK: - Inicializador
    // Necesario para inicializar State y configurar la clave de UserDefaults
    init(categoria: ClaseCategoria, pagos: [PagoLocal]) {
        self.categoria = categoria
        self.pagos = pagos

        // --- Configura Clave y Carga Inicial para Fecha Persistente ---
        let key = "ultimaFechaSeleccionada_\(categoria.nombre)" // Usa el nombre como clave
        self.userDefaultsKey = key // Guarda la clave para usarla después

        var initialInterval: TimeInterval? = nil
        // Carga desde UserDefaults ANTES de inicializar el State
        if UserDefaults.standard.object(forKey: key) != nil {
            initialInterval = UserDefaults.standard.double(forKey: key)
            // Asegúrate de que no sea 0 por defecto si la clave existe pero el valor es 0
            if initialInterval == 0 && UserDefaults.standard.object(forKey: key) as? Double == 0 {
                 // Podría ser un 0 legítimo, pero es raro para TimeInterval. Decide si quieres tratar 0 como nil.
                 // Para simplificar, si es 0, lo tratamos como si no hubiera fecha guardada.
                 // initialInterval = nil
            }
        }

        // --- Inicializa los @State ---
        // Es obligatorio inicializar TODOS los @State aquí
        self._ultimaFechaSeleccionadaIntervalState = State(initialValue: initialInterval) // <-- Usa el valor cargado
        self._mesSeleccionado = State(initialValue: Calendar.current.component(.month, from: Date()))
        self._anioSeleccionado = State(initialValue: Calendar.current.component(.year, from: Date()))
        self._fechaSeleccionada = State(initialValue: nil) // Se establecerá en onAppear después de validar
        self._mostrarSoloActivos = State(initialValue: true)
        self._mostrarPickerFecha = State(initialValue: false)
        self._textoBusqueda = State(initialValue: "")
        self._asistenciasManual = State(initialValue: []) // Comienza vacío
    }

    // --- Propiedades Computadas ---
    private var alumnosFiltrados: [Alumno] {
        alumnos.filter {
            // Asumiendo que Alumno tiene una propiedad 'categoriaNombre' o similar
            // Si 'categoria' en Alumno es una relación, necesitarías $0.categoria?.nombre == categoria.nombre
            // Adaptar esta línea según tu modelo Alumno:
            ($0.categoria ?? "") == categoria.nombre && // <-- REVISA ESTA LÍNEA según tu modelo Alumno
            (!mostrarSoloActivos || $0.activo) &&
            (textoBusqueda.isEmpty || $0.nombre.localizedCaseInsensitiveContains(textoBusqueda))
        }.sorted { $0.nombre.localizedStandardCompare($1.nombre) == .orderedAscending }
    }

    private var fechasDelMes: [Date] {
        generarFechasDeClaseDelMes(anio: anioSeleccionado, mes: mesSeleccionado)
    }

    // --- Funciones Helper ---

    // Carga asistencias del mes/año actual en asistenciasManual
    private func cargarAsistencias() {
        let calendar = Calendar.current
        let components = DateComponents(year: anioSeleccionado, month: mesSeleccionado)
        guard let inicioMes = calendar.date(from: components),
              let finMes = calendar.date(byAdding: .month, value: 1, to: inicioMes) else {
            asistenciasManual = []
            return
        }

        // Necesitamos el ID persistente de la categoría para el predicado
        // Asegúrate de que ClaseCategoria tenga una forma estable de identificarse
        // Usaremos persistentModelID como fallback si no hay un UUID 'id' explícito
        let categoriaPersistentId = categoria.persistentModelID // <-- ID interno de SwiftData

        // Predicado para filtrar por el ID persistente de la categoría y rango de fechas
        let predicado = #Predicate<Asistencia> { asistencia in
            // Compara el categoriaID (que debe ser PersistentIdentifier en Asistencia)
            // con el ID persistente de la categoría actual
            asistencia.categoriaID == categoriaPersistentId &&
            asistencia.fecha >= inicioMes &&
            asistencia.fecha < finMes
        }

        let fetchDescriptor = FetchDescriptor<Asistencia>(predicate: predicado, sortBy: [SortDescriptor(\.fecha)])
        do {
            asistenciasManual = try modelContext.fetch(fetchDescriptor)
            print("Cargadas \(asistenciasManual.count) asistencias para \(nombreMes(mesSeleccionado))/\(anioSeleccionado)")
        } catch {
            print("Error cargando asistencias filtradas: \(error)")
            asistenciasManual = []
        }
    }


    // Genera fechas de clase del mes
    private func generarFechasDeClaseDelMes(anio: Int, mes: Int) -> [Date] {
        var fechas: [Date] = []
        let calendar = Calendar.current
        let diaSemanaClase = diaDeClase(categoria.nombre)
        if diaSemanaClase == 0 { return [] }
        if let rangoMes = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: anio, month: mes))!) {
            for dia in rangoMes {
                let components = DateComponents(year: anio, month: mes, day: dia)
                if let fecha = calendar.date(from: components),
                   calendar.component(.weekday, from: fecha) == diaSemanaClase {
                    fechas.append(fecha)
                }
            }
        }
        return fechas
    }

    // Busca asistencia para alumno/fecha en el array temporal
    private func asistenciaPara(alumno: Alumno, fecha: Date) -> Asistencia? {
         // Usa el ID persistente del alumno para la comparación
         let alumnoPersistentId = alumno.persistentModelID
         return asistenciasManual.first { $0.alumnoID == alumnoPersistentId && Calendar.current.isDate($0.fecha, inSameDayAs: fecha) }
     }


    // Feedback
    private func vibracionYsonido() {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    // Marca/desmarca asistencia (Guarda en DB, actualiza array temporal)
    private func toggleAsistencia(alumno: Alumno, fecha: Date, asistio: Bool) {
        vibracionYsonido()

        let alumnoPersistentId = alumno.persistentModelID
        let categoriaPersistentId = categoria.persistentModelID

        if let index = asistenciasManual.firstIndex(where: { $0.alumnoID == alumnoPersistentId && Calendar.current.isDate($0.fecha, inSameDayAs: fecha) }) {
            asistenciasManual[index].asistio = asistio
        } else {
            // Usa los IDs persistentes al crear la nueva asistencia
            let nueva = Asistencia(fecha: fecha, alumnoID: alumnoPersistentId, categoriaID: categoriaPersistentId, asistio: asistio)
            modelContext.insert(nueva)
            asistenciasManual.append(nueva)
        }
        do {
            try modelContext.save()
            print("Asistencia guardada para \(alumno.nombre) en fecha \(formatearFecha(fecha)) -> \(asistio)")
        } catch {
            print("Error guardando asistencia: \(error.localizedDescription)")
        }
    }

    // Color botones
    private func colorAsistencia(alumno: Alumno, fecha: Date, tipo: Bool) -> Color {
        if let asistencia = asistenciaPara(alumno: alumno, fecha: fecha) {
            return asistencia.asistio == tipo ? (tipo ? .green : .red) : .gray.opacity(0.4)
        } else {
            return .gray.opacity(0.4)
        }
    }

    // Formato fecha
    private func formatearFecha(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: fecha)
    }

    // Nombre mes
    private func nombreMes(_ numero: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        guard numero >= 1 && numero <= 12 else { return "" }
        return formatter.monthSymbols[numero - 1].capitalized
    }

    // Dia semana
    private func diaDeClase(_ nombreCategoria: String) -> Int {
        let nombreLower = nombreCategoria.lowercased()
        if nombreLower.contains("lunes") { return 2 }
        if nombreLower.contains("martes") { return 3 }
        if nombreLower.contains("miércoles") || nombreLower.contains("miercoles") { return 4 }
        if nombreLower.contains("jueves") { return 5 }
        if nombreLower.contains("viernes") { return 6 }
        if nombreLower.contains("sábado") || nombreLower.contains("sabado") { return 7 }
        if nombreLower.contains("domingo") { return 1 }
        print("Advertencia: No se pudo determinar el día de clase para la categoría '\(nombreCategoria)'")
        return 0
    }

    // --- Cuerpo de la Vista (Body) ---
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Espaciado entre secciones

                // --- Sección Título ---
                Text(categoria.nombre)
                    .font(.largeTitle.bold())
                    .padding(.horizontal)
                    .padding(.bottom, -10) // Reduce espacio antes del siguiente bloque

                // --- Estilo iOS Sección Filtros ---
                VStack(spacing: 0) { // Sin espacio interno para que Divider funcione bien
                    Toggle("Mostrar solo activos", isOn: $mostrarSoloActivos)
                        .padding(.horizontal).padding(.vertical, 8) // Padding para contenido
                    Divider().padding(.leading) // Divider indentado
                    HStack {
                         Image(systemName: "magnifyingglass").foregroundColor(.secondary).padding(.leading)
                         TextField("Buscar alumno...", text: $textoBusqueda)
                             .textFieldStyle(.plain).padding(.vertical, 10)
                    }.padding(.trailing) // Padding para que texto no pegue al borde
                }
                .background(Color(UIColor.secondarySystemBackground)) // Fondo adaptable
                .cornerRadius(10) // Esquinas redondeadas
                .padding(.horizontal) // Padding externo para efecto inset


                // --- Estilo iOS Sección Selección Mes/Año ---
                VStack(alignment: .leading, spacing: 5) { // Contenedor si quieres título encima
                    // Text("SELECCIONAR MES").font(.caption).foregroundColor(.secondary)... // Título opcional
                    HStack {
                        Image(systemName: "calendar").foregroundColor(.accentColor)
                        Text("\(nombreMes(mesSeleccionado)) \(anioSeleccionado)").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.secondary)
                    }
                    .padding() // Padding interno
                    .background(Color(UIColor.secondarySystemBackground)) // Fondo
                    .cornerRadius(10) // Esquinas
                    .contentShape(Rectangle())
                    .onTapGesture { mostrarPickerFecha.toggle(); vibracionYsonido() }
                    .padding(.horizontal) // Padding externo
                }


                // --- Sección Días de Clase ---
                 VStack(alignment: .leading, spacing: 5) {
                     Text("DÍAS DE CLASE").font(.caption).foregroundColor(.secondary).padding(.horizontal)
                     ScrollView(.horizontal, showsIndicators: false) {
                         HStack(spacing: 10) {
                             ForEach(fechasDelMes, id: \.self) { fecha in
                                 Button { fechaSeleccionada = fecha; vibracionYsonido() } label: {
                                     Text(formatearFecha(fecha))
                                         .font(.footnote.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 8)
                                         .background(Calendar.current.isDate(fechaSeleccionada ?? .distantPast, inSameDayAs: fecha) ? Color.blue.opacity(0.15) : Color(UIColor.tertiarySystemBackground))
                                         .clipShape(Capsule())
                                         .overlay(Capsule().stroke(Calendar.current.isDate(fechaSeleccionada ?? .distantPast, inSameDayAs: fecha) ? Color.blue : Color.clear, lineWidth: 1.5))
                                         .foregroundColor(Calendar.current.isDate(fechaSeleccionada ?? .distantPast, inSameDayAs: fecha) ? .blue : .primary)
                                 }
                             }
                         }.padding(.horizontal).padding(.vertical, 8) // Padding interno del scroll
                     }
                     // Sin padding externo para que llegue a los bordes
                 }


                // --- Estilo iOS Sección Lista de Asistencia ---
                if let fecha = fechaSeleccionada, fechasDelMes.contains(where: { Calendar.current.isDate($0, inSameDayAs: fecha) }) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ASISTENCIA – \(formatearFecha(fecha).uppercased())")
                            .font(.caption).foregroundColor(.secondary).padding(.horizontal)
                        VStack(spacing: 0) { // Sin espacio entre filas
                            ForEach(alumnosFiltrados) { alumno in
                                HStack {
                                    // --- Color Chivato Amarillo ---
                                    if asistenciaPara(alumno: alumno, fecha: fecha) == nil {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.yellow) // AMARILLO
                                            .font(.subheadline).frame(width: 20, alignment: .center)
                                    } else { Spacer().frame(width: 20) }

                                    NavigationLink(destination: DetalleAsistenciaAlumnoView(alumno: alumno, categoria: categoria, fecha: fecha, pagos: pagos)) {
                                        Text(alumno.nombre).lineLimit(1)
                                    }
                                    Spacer()
                                    Button { toggleAsistencia(alumno: alumno, fecha: fecha, asistio: true) } label: {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(colorAsistencia(alumno: alumno, fecha: fecha, tipo: true)).imageScale(.large)
                                    }.padding(.leading, 10).contentShape(Rectangle())
                                    Button { toggleAsistencia(alumno: alumno, fecha: fecha, asistio: false) } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(colorAsistencia(alumno: alumno, fecha: fecha, tipo: false)).imageScale(.large)
                                    }.padding(.leading, 6).contentShape(Rectangle())
                                }
                                .padding(.horizontal) // Padding de contenido de fila
                                .padding(.vertical, 12) // Altura de fila

                                // Divider indentado entre filas
                                if alumno.id != alumnosFiltrados.last?.id {
                                     Divider().padding(.leading)
                                 }
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground)) // Fondo
                        .cornerRadius(10) // Esquinas
                        .padding(.horizontal) // Padding externo
                    }
                } else if fechaSeleccionada != nil {
                    Text("Selecciona un día de clase válido.")
                        .foregroundColor(.secondary).padding().frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer().frame(height: 10) // Espacio final
            }
            .padding(.top) // Espacio arriba del todo
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea()) // Fondo principal
        .navigationTitle(categoria.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("onAppear ejecutado. Mes: \(mesSeleccionado), Año: \(anioSeleccionado)")
            cargarAsistencias() // Carga asistencias para mes/año actual

            // --- Restaura y valida fecha seleccionada ---
            var fechaRestaurada: Date? = nil
            // Lee el valor del State (que se cargó desde UserDefaults en init)
            if let interval = ultimaFechaSeleccionadaIntervalState, interval != 0 {
                let possibleDate = Date(timeIntervalSince1970: interval)
                // Recalcula fechas del mes para validar contra el estado ACTUAL
                let currentFechasDelMes = generarFechasDeClaseDelMes(anio: anioSeleccionado, mes: mesSeleccionado)
                if currentFechasDelMes.contains(where: { Calendar.current.isDate($0, inSameDayAs: possibleDate)}) {
                    fechaRestaurada = possibleDate
                    print("Fecha restaurada desde State/UserDefaults: \(formatearFecha(fechaRestaurada!))")
                } else {
                     print("Fecha restaurada (\(formatearFecha(possibleDate))) no pertenece al mes/año \(mesSeleccionado)/\(anioSeleccionado). Descartando.")
                }
            }

            // Establece fechaSeleccionada final para onAppear
             if let fechaValidaRestaurada = fechaRestaurada {
                  fechaSeleccionada = fechaValidaRestaurada
             } else if fechaSeleccionada == nil { // Solo si no se restauró O si estaba nil
                  print("Calculando fecha por defecto...")
                  let currentFechasDelMes = generarFechasDeClaseDelMes(anio: anioSeleccionado, mes: mesSeleccionado)
                  let hoy = Calendar.current.startOfDay(for: Date())
                  fechaSeleccionada = currentFechasDelMes.first { Calendar.current.startOfDay(for: $0) >= hoy } ?? currentFechasDelMes.last
                  if let fDef = fechaSeleccionada { print("Fecha por defecto establecida: \(formatearFecha(fDef))") }
             }
        }
        .onChange(of: [mesSeleccionado, anioSeleccionado]) { _, _ in
             print("Mes/Año cambiado a \(nombreMes(mesSeleccionado))/\(anioSeleccionado)")
             cargarAsistencias() // Recarga asistencias

             // Valida si la fecha seleccionada actual sigue en el nuevo mes
             let nuevasFechas = generarFechasDeClaseDelMes(anio: anioSeleccionado, mes: mesSeleccionado)
             if let fecha = fechaSeleccionada, !nuevasFechas.contains(where: { Calendar.current.isDate($0, inSameDayAs: fecha) }) {
                  print("Fecha seleccionada \(formatearFecha(fecha)) ya no es válida. Seleccionando la primera.")
                  fechaSeleccionada = nuevasFechas.first // Selecciona la primera si no es válida
              } else if fechaSeleccionada == nil { // Si no había ninguna seleccionada
                  fechaSeleccionada = nuevasFechas.first
                  if let fDef = fechaSeleccionada { print("Fecha seleccionada era nil. Establecida a primera: \(formatearFecha(fDef))") }
              }
        }
        // --- Guarda fecha seleccionada en UserDefaults ---
        .onChange(of: fechaSeleccionada) { _, nuevaFecha in
             if let date = nuevaFecha {
                 let interval = date.timeIntervalSince1970
                 UserDefaults.standard.set(interval, forKey: userDefaultsKey) // Guarda
                 ultimaFechaSeleccionadaIntervalState = interval // Actualiza State también
                 print("Guardando fecha en UserDefaults (\(userDefaultsKey)): \(formatearFecha(date))")
             } else {
                  UserDefaults.standard.removeObject(forKey: userDefaultsKey) // Limpia
                  ultimaFechaSeleccionadaIntervalState = nil // Limpia State
                 print("Fecha deselecciomada, eliminada de UserDefaults (\(userDefaultsKey)).")
             }
        }
        .sheet(isPresented: $mostrarPickerFecha) {
            // --- Hoja para seleccionar Mes y Año ---
            VStack(spacing: 16) {
                 Text("Selecciona mes y año").font(.headline).padding(.top)
                HStack(spacing: 0) {
                    Picker("Mes", selection: $mesSeleccionado) {
                        ForEach(1...12, id: \.self) { Text(nombreMes($0)).tag($0) }
                    }.pickerStyle(.wheel).frame(maxWidth: .infinity)
                    Picker("Año", selection: $anioSeleccionado) {
                         let currentYear = Calendar.current.component(.year, from: Date())
                         ForEach((currentYear - 5)...(currentYear + 5), id: \.self) { Text(String($0)).tag($0) }
                    }.pickerStyle(.wheel).frame(maxWidth: .infinity)
                }.frame(height: 180)
                Button("Aplicar") { mostrarPickerFecha = false; vibracionYsonido() }
                .buttonStyle(.borderedProminent).padding(.bottom).padding(.horizontal)
            }
            .presentationDetents([.height(300)]).presentationDragIndicator(.visible).presentationCornerRadius(20)
        }
    } // Fin Body
} // Fin Struct

// --- IMPORTANTE: Revisa tus Modelos ---
// 1. Modelo Alumno: Asegúrate de que la propiedad para comparar con `categoria.nombre`
//    sea correcta en `alumnosFiltrados`. Si usas una relación, podría ser `$0.categoria?.nombre`.
//    Asegúrate de que Alumno tenga `id` (preferiblemente UUID) o usa `persistentModelID`.
// 2. Modelo ClaseCategoria: Usa `persistentModelID` para comparaciones si no tiene `id: UUID`.
//    Asegúrate de que tenga la propiedad `nombre`.
// 3. Modelo Asistencia: Asegúrate de que `alumnoID` y `categoriaID` sean del tipo
//    `PersistentIdentifier` para que coincidan con `.persistentModelID` de Alumno y ClaseCategoria.

import SwiftUI

struct CalendarioAsistenciaView: View {
    let alumno: Alumno
    let mes: Int
    let año: Int

    @State private var asistencia: [Int: String] = [:] // Día del mes -> estado: "✓", "J", "X"

    let diasSemana = ["L", "M", "X", "J", "V", "S", "D"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("\(alumno.nombre) - \(nombreMes(mes)) \(año)")
                    .font(.title2)
                    .padding(.bottom, 10)

                HStack {
                    ForEach(diasSemana, id: \.self) { dia in
                        Text(dia)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }

                let calendario = generarCalendario(mes: mes, año: año)
                ForEach(calendario, id: \.self) { semana in
                    HStack {
                        ForEach(semana, id: \.self) { dia in
                            if let dia = dia {
                                Menu {
                                    Button("Presente ✓") {
                                        asistencia[dia] = "✓"
                                    }
                                    Button("Justificada J") {
                                        asistencia[dia] = "J"
                                    }
                                    Button("No justificada X") {
                                        asistencia[dia] = "X"
                                    }
                                    Button("Borrar") {
                                        asistencia.removeValue(forKey: dia)
                                    }
                                } label: {
                                    Text(asistencia[dia] ?? "\(dia)")
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background(asistencia[dia] == "✓" ? Color.green.opacity(0.3) :
                                                    asistencia[dia] == "J" ? Color.orange.opacity(0.3) :
                                                    asistencia[dia] == "X" ? Color.red.opacity(0.3) :
                                                    Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity, minHeight: 40)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Asistencia")
    }

    // Función auxiliar para generar el calendario en semanas
    func generarCalendario(mes: Int, año: Int) -> [[Int?]] {
        var calendario: [[Int?]] = []
        var semana: [Int?] = []

        let calendar = Calendar.current
        let dateComponents = DateComponents(year: año, month: mes, day: 1)

        guard let primerDiaMes = calendar.date(from: dateComponents),
              let rangoDias = calendar.range(of: .day, in: .month, for: primerDiaMes)
        else { return [] }

        let primerDiaSemana = calendar.component(.weekday, from: primerDiaMes)
        let espacioInicio = (primerDiaSemana + 5) % 7

        semana.append(contentsOf: Array(repeating: nil, count: espacioInicio))

        for dia in rangoDias {
            semana.append(dia)
            if semana.count == 7 {
                calendario.append(semana)
                semana = []
            }
        }

        if !semana.isEmpty {
            semana.append(contentsOf: Array(repeating: nil, count: 7 - semana.count))
            calendario.append(semana)
        }

        return calendario
    }

    func nombreMes(_ mes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.monthSymbols[mes - 1].capitalized
    }
}

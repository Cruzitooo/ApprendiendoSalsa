//
//  ConceptosManager.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 19/4/25.
//


import SwiftUI
import Foundation

class ConceptosManager: ObservableObject {
    @AppStorage("conceptosGuardadosData") private var conceptosGuardadosData: String = ""

    @Published var conceptos: [String] = []

    init() {
        loadConceptos()
    }

    private func loadConceptos() {
        if let data = conceptosGuardadosData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            conceptos = decoded
        } else {
            conceptos = ["Mensualidad", "Minimo Obligatorio", "Clase Suelta", "Privada", "Intensivo", "Evento"]
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(conceptos),
           let string = String(data: encoded, encoding: .utf8) {
            conceptosGuardadosData = string
        }
    }

    func añadir(_ concepto: String) {
        let nuevo = concepto.trimmingCharacters(in: .whitespaces)
        guard !nuevo.isEmpty && !conceptos.contains(nuevo) else { return }
        conceptos.append(nuevo)
        save()
    }

    func eliminar(_ concepto: String) {
        conceptos.removeAll { $0 == concepto }
        save()
    }
}

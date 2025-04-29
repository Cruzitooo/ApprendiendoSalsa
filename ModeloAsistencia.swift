//
//  ModeloAsistencia.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 22/4/25.
//

import Foundation
import SwiftData

@Model
class Asistencia {
    var id: UUID
    var fecha: Date
    var alumnoID: PersistentIdentifier // <--- ¡Ajá! Aquí usas PersistentIdentifier
    var categoriaID: PersistentIdentifier // <--- ¡Y aquí también!
    var asistio: Bool
    var justificada: Bool?

    init(fecha: Date, alumnoID: PersistentIdentifier, categoriaID: PersistentIdentifier, asistio: Bool, justificada: Bool? = nil) {
        self.id = UUID()
        self.fecha = fecha
        self.alumnoID = alumnoID
        self.categoriaID = categoriaID
        self.asistio = asistio
        self.justificada = justificada
    }
}

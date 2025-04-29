// ModeloPago.swift
// ApprendiendoSalsa

import Foundation
import SwiftData

@Model
class PagoLocal {
    var concepto: String
    var importe: Double
    var fecha: Date
    var estado: String
    var alumnoID: PersistentIdentifier  // Cambiar UUID por PersistentIdentifier

    init(concepto: String, importe: Double, fecha: Date, estado: String, alumnoID: PersistentIdentifier) {
        self.concepto = concepto
        self.importe = importe
        self.fecha = fecha
        self.estado = estado
        self.alumnoID = alumnoID
    }
}


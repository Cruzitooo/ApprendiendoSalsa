//
//  PagoAppEfectivo.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 26/4/25.
//

import Foundation
import SwiftData

@Model
class PagoAppEfectivo {
    var id: UUID
    var alumnoNombre: String
    var importe: Double
    var estado: String // Ejemplo: "pagado" o "pendiente"
    var concepto: String
    var claseNombre: String? // Clase o sección (opcional)
    var fechaCreacion: Date

    init(
        id: UUID = UUID(),
        alumnoNombre: String,
        importe: Double,
        estado: String,
        concepto: String,
        claseNombre: String? = nil,
        fechaCreacion: Date = Date()
    ) {
        self.id = id
        self.alumnoNombre = alumnoNombre
        self.importe = importe
        self.estado = estado
        self.concepto = concepto
        self.claseNombre = claseNombre
        self.fechaCreacion = fechaCreacion
    }
}

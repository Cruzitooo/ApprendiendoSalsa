//
//  PagoAppStripe.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 26/4/25.
//

import Foundation
import SwiftData

@Model
class PagoAppStripe {
    @Attribute(.unique) var id: UUID
    var alumnoNombre: String
    var concepto: String
    var importe: Double
    var fechaCreacion: Date
    var estado: String   // "pendiente", "pagado", "fallido", etc.
    var metodoPago: String  // "stripe" o "efectivo"
    var stripeId: String?   // Opcional: solo si fue pago por Stripe
    var claseNombre: String?  // NUEVO: nombre de la sección o clase (Clase Lunes, Martes, etc.)

    init(
        alumnoNombre: String,
        concepto: String,
        importe: Double,
        fechaCreacion: Date = Date(),
        estado: String = "pendiente",
        metodoPago: String = "stripe",
        stripeId: String? = nil,
        claseNombre: String? = nil
    ) {
        self.id = UUID()
        self.alumnoNombre = alumnoNombre
        self.concepto = concepto
        self.importe = importe
        self.fechaCreacion = fechaCreacion
        self.estado = estado
        self.metodoPago = metodoPago
        self.stripeId = stripeId
        self.claseNombre = claseNombre
    }
}

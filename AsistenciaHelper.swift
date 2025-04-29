//
//  AsistenciaHelper.swift
//  ApprendiendoSalsa
//
//  Creado por Christian & ChatGPT el 22/04/2025
//

import Foundation
import SwiftData

/// Función reutilizable para marcar o desmarcar asistencia de un alumno.
/// Si ya existe una asistencia para esa fecha y categoría, la alterna.
/// Si no existe, la crea como presente (asistió).
func toggleAsistencia(
    alumno: Alumno,
    fecha: Date,
    categoria: ClaseCategoria,
    asistencias: [Asistencia],
    context: ModelContext
) {
    if let existente = asistencias.first(where: {
        $0.alumnoID == alumno.id &&
        Calendar.current.isDate($0.fecha, inSameDayAs: fecha) &&
        $0.categoriaID == categoria.id
    }) {
        existente.asistio.toggle()
        try? context.save()
    } else {
        let nueva = Asistencia(
            fecha: fecha,
            alumnoID: alumno.id,
            categoriaID: categoria.id,
            asistio: true,
            justificada: nil
        )
        context.insert(nueva)
        try? context.save()
    }
}

/*
 * Proyecto: jpgreducer
 * Fichero: jpgreducer.prg
 * Descripción: Módulo de entrada a la aplicación
 * Autor: Ignacio Ortiz de Zúñiga
 * Fecha: 05/05/2015
 */

#include "Xailer.ch"

Procedure Main()

   Application:cTitle := "JPG size reducer"
   TForm1():New( Application ):Show()
   Application:Run()

Return

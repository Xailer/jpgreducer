/*
 * Proyecto: jpgreducer
 * Fichero: jpgreducer.prg
 * Descripci�n: M�dulo de entrada a la aplicaci�n
 * Autor: Ignacio Ortiz de Z��iga
 * Fecha: 05/05/2015
 */

#include "Xailer.ch"

Procedure Main()

   Application:cTitle := "JPG size reducer"
   TForm1():New( Application ):Show()
   Application:Run()

Return

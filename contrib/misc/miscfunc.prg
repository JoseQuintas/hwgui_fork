/*
 * $Id$
 *
 * HWGUI utility functions for dynamic object manipulation.
 * Provides methods to add/remove properties and methods at runtime,
 * and a bulk property setter for controls.
 *
 * 2026-09-08 - Added English comments, fixed ADDPROPERTY to accept
 *              .F. and 0 as valid values, improved readability.
 */

/*
 * ADDMETHOD( oObject, cMethodName, pFunction ) -> lSuccess
 * Adds a new method to an object if it doesn't already exist.
 *   oObject    - object reference
 *   cMethodName - name of the method (string)
 *   pFunction   - code block or function pointer to execute
 * Returns .T. on success, .F. otherwise.
 */
FUNCTION ADDMETHOD( oObjectName, cMethodName, pFunction )

   IF ValType( oObjectName ) == "O" .AND. ! Empty( cMethodName )
      IF ! __ObjHasMsg( oObjectName, cMethodName )
         __objAddMethod( oObjectName, cMethodName, pFunction )
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

/*
 * ADDPROPERTY( oObject, cPropertyName, [eNewValue] ) -> lSuccess
 * Adds a new data property to an object. If eNewValue is provided,
 * the property is initialized with that value (block evaluated if given).
 *   oObject      - object reference
 *   cPropertyName - property name (string)
 *   eNewValue     - optional initial value (or code block)
 * Returns .T. on success, .F. otherwise.
 * FIX: Now correctly accepts .F. and 0 as valid initial values.
 */
FUNCTION ADDPROPERTY( oObjectName, cPropertyName, eNewValue )

   IF ValType( oObjectName ) == "O" .AND. ! Empty( cPropertyName )
      IF ! __objHasData( oObjectName, cPropertyName )
         IF Empty( __objAddData( oObjectName, cPropertyName ) )
            RETURN .F.
         ENDIF
      ENDIF
      /* Check for explicit value (allow .F. and 0) */
      IF eNewValue != NIL
         IF ValType( eNewValue ) == "B"
            oObjectName: & ( cPropertyName ) := Eval( eNewValue )
         ELSE
            oObjectName: & ( cPropertyName ) := eNewValue
         ENDIF
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

/*
 * REMOVEPROPERTY( oObject, cPropertyName ) -> lSuccess
 * Removes a data property from an object.
 * Returns .T. if the property existed and was removed, .F. otherwise.
 */
FUNCTION REMOVEPROPERTY( oObjectName, cPropertyName )

   IF ValType( oObjectName ) == "O" .AND. ! Empty( cPropertyName ) .AND. ;
         __objHasData( oObjectName, cPropertyName )
      RETURN Empty( __objDelData( oObjectName, cPropertyName ) )
   ENDIF

   RETURN .F.

/*
 * hwg_SetAll( oWnd, cProperty, Value, [aControls], [cClass] ) -> NIL
 * Sets a property value for all controls in a list.
 *   oWnd       - window/dialog object containing the controls
 *   cProperty  - property name to set (string)
 *   Value      - new value (any type)
 *   aControls  - optional array of controls, or a string naming a
 *                property of oWnd that holds the controls array.
 *                Defaults to oWnd:aControls.
 *   cClass     - optional class name to filter controls (case-insensitive).
 * If Value is NIL, the property is accessed (getter) without assignment
 * (can trigger side-effects).
 */
FUNCTION hwg_SetAll( oWnd, cProperty, Value, aControls, cClass )

   LOCAL nLen, i

   /* Resolve the control list */
   aControls := iif( Empty( aControls ), oWnd:aControls, aControls )
   nLen := iif( ValType( aControls ) == "C", Len( oWnd:&aControls ), Len( aControls ) )

   FOR i = 1 TO nLen
      IF ValType( aControls ) == "C"
         /* aControls is the name of an array property in oWnd */
         oWnd:&aControls[ i ]:&cProperty := Value
      ELSEIF cClass == NIL .OR. Upper( cClass ) == aControls[ i ]:ClassName
         IF Value == NIL
            /* Just evaluate the property (getter), no assignment */
            __mvPrivate( "oCtrl" )
            &( "oCtrl" ) := aControls[ i ]
            &( "oCtrl:" + cProperty )
         ELSE
            aControls[ i ]:&cProperty := Value
         ENDIF
      ENDIF
   NEXT

   RETURN NIL
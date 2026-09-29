IFNDEF PSEUDO_OOP_VECTOR_INC
PSEUDO_OOP_VECTOR_INC equ 1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                TYPES                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Vector STRUCT
    pData DWORD ?
    dwSize DWORD ?
    dwCapacity DWORD ?
    pVTable DWORD ? 
Vector ENDS

Vector_get_at_t TYPEDEF PROTO STDCALL : ptr Vector, :DWORD
Vector_get_data_t TYPEDEF PROTO STDCALL : ptr Vector
Vector_get_size_t TYPEDEF PROTO STDCALL : ptr Vector
Vector_capacity_t TYPEDEF PROTO STDCALL : ptr Vector
Vector_push_back_t TYPEDEF PROTO STDCALL : ptr Vector, :DWORD
Vector_free_t TYPEDEF PROTO STDCALL : ptr Vector

VectorVTable STRUCT
    get_at DWORD ?
    get_data DWORD ?
    ;empty DWORD ?
    get_size DWORD ?
    ;max_size DWORD ?
    ;reserve DWORD ?
    capacity DWORD ?
    ;clear DWORD ?
    ;insert DWORD ?
    ;erase DWORD ?
    push_back DWORD ?
    ;resize DWORD ?
    ;is_eq DWORD ?
    free DWORD ?
VectorVTable ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;         PUBLIC FUNCTIONS            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Vector_New_Filled PROTO dwSize: DWORD, dwData: DWORD

Vector_Free PROTO pThis: ptr Vector

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                MACROS               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VECTOR_METHOD MACRO pObj, methodName, args:VARARG
    mov eax, pObj
    mov eax, [eax].Vector.pVTable
    IFB <args>
        invoke Vector_&methodName&_t PTR [eax + VectorVTable.methodName], pObj
    ELSE
        invoke Vector_&methodName&_t PTR [eax + VectorVTable.methodName], pObj, args
    ENDIF
ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              VARIABLES              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EXTERNDEF Vector_vt: VectorVTable

ENDIF
.386
.model flat, stdcall
option casemap:none
include \masm32\include\msvcrt.inc
includelib \masm32\lib\msvcrt.lib
include .\Vector.inc

.data
    PUBLIC Vector_vt
    Vector_vt VectorVTable <Vector__get_at, Vector__get_data, Vector__get_size, Vector__empty, Vector__reserve, Vector_capacity, Vector__push_back, Vector__is_eq, Vector__free>
    VECTOR_MAX_SIZE DWORD 0FFFFFFFFh

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Private methods with private functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_Vector__calculate_growth PROC uses ebx ecx edx, pThis: ptr Vector, dwNewSize: DWORD
    mov ebx, pThis
    assume ebx: ptr Vector

    mov ecx, VECTOR_MAX_SIZE
    mov edx, [ebx].dwCapacity
    shr edx, 1
    add edx, [ebx].dwCapacity
    .IF CARRY?
        mov eax, ecx                   ; overflow -> MAX_SIZE
    .ELSE
        mov eax, edx                   ; eax = _Geometric
    .ENDIF
    
    mov ecx, dwNewSize
    cmp eax, ecx
    .IF CARRY?                         ; unsigned (eax < dwNewSize)
        mov eax, ecx                   ; insufficient -> dwNewSize
    .ENDIF
    
    assume ebx:nothing
    ret
_Vector__calculate_growth ENDP

; Reallocates to max between NewSize and OldSize+OldSize/2
_Vector__max_reallocate PROC uses ebx ecx edx esi, pThis: ptr Vector, dwNewSize: DWORD
    mov ebx, pThis
    assume ebx: ptr Vector
    
    mov ecx, dwNewSize
    mov edx, pThis
    ; eax := new capacity to reallocate
    invoke _Vector__calculate_growth, edx, ecx
    mov esi, eax
    mov ecx, esi
    imul ecx, (sizeof DWORD)
    ; eax := pointer ot new data
    invoke crt_realloc, [ebx].pData, ecx
    
    ; if realloc finishes successfully
    .IF eax != 0
        mov [ebx].dwCapacity, esi
        mov [ebx].pData, eax
    .ENDIF
    
    assume ebx:nothing
    ret
_Vector__max_reallocate ENDP

_Vector__fill PROC uses ebx ecx edx, pThis: ptr Vector, dwData: DWORD
    mov ebx, pThis
    assume ebx: ptr Vector
    
    mov ecx, [ebx].dwSize
    .IF ecx == 0
        ret
    .ENDIF

    .REPEAT
        dec ecx
        mov edx, [ebx].pData
        mov eax, dwData
        mov DWORD ptr [edx + ecx * (sizeof DWORD)], eax
    .UNTIL ecx == 0
    
    assume ebx:nothing
    ret
_Vector__fill ENDP

_Vector__constructor_base PROC uses ebx
    invoke crt_malloc, sizeof Vector
    .IF eax == 0
        ret
    .ENDIF
    mov ebx, eax
    assume ebx: ptr Vector
    mov [ebx].pVTable, offset Vector_vt
    mov [ebx].pData, 0
    mov [ebx].dwSize, 0
    mov [ebx].dwCapacity, 0
    mov eax, ebx
    assume ebx:nothing
    ret 
_Vector__constructor_base ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public methods with private functions  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Vector__get_at PROC uses ebx ecx edx, pThis: ptr Vector, index: DWORD
    mov ebx, pThis
    assume ebx: ptr Vector
    
    mov edx, [ebx].pData
    mov ecx, index
    mov eax, [edx + ecx * (sizeof DWORD)]
    
    assume ebx:nothing
    ret
Vector__get_at ENDP

Vector__get_data PROC pThis: ptr Vector
    mov eax, pThis
    assume eax: ptr Vector
    
    mov eax, [eax].pData
    
    assume eax:nothing
    ret
Vector__get_data ENDP

Vector__get_size PROC pThis: ptr Vector
    mov eax, pThis
    assume eax: ptr Vector
    
    mov eax, [eax].dwSize
    
    assume eax:nothing
    ret
Vector__get_size ENDP

Vector__empty PROC pThis: ptr Vector
    invoke Vector__get_size, pThis
    ; Convert to bool: 0 if 0, 1 elsewhere
    .IF eax != 0
        mov eax, 1
    .ENDIF
    ret
Vector__empty ENDP

Vector__reserve PROC uses ebx, pThis: ptr Vector, dwNewCapacity: DWORD
    mov ebx, pThis
    assume ebx: ptr Vector
    .IF ebx == 0
        mov eax, dwNewCapacity
        imul eax, sizeof DWORD
        invoke crt_malloc, eax
        .IF eax == 0
            ret
        .ENDIF
        mov [ebx].pData, eax
        mov eax, dwNewCapacity
        mov [ebx].dwSize, eax
        mov [ebx].dwCapacity, eax
    .ELSE
        invoke _Vector__max_reallocate, pThis, dwNewCapacity
    .ENDIF
    
    assume ebx:nothing
    ret
Vector__reserve ENDP

Vector_capacity PROC pThis: ptr Vector
    mov eax, pThis
    assume eax: ptr Vector
    
    mov eax, [eax].dwCapacity
    
    assume eax:nothing
    ret
Vector_capacity ENDP

Vector__push_back PROC uses ebx ecx edx, pThis: ptr Vector, dwData: DWORD
    mov ebx, pThis
    assume ebx: ptr Vector
    
    mov eax, [ebx].dwSize
    .IF eax < [ebx].dwCapacity
        mov edx, [ebx].pData
        mov ecx, [ebx].dwSize
        mov eax, dwData
        mov DWORD ptr [edx + ecx * (sizeof DWORD)], eax
        inc [ebx].dwSize
    .ELSE
        mov eax, pThis
        mov ecx, [ebx].dwSize
        inc ecx
        invoke _Vector__max_reallocate, eax, ecx
        ; if eax != 0 then reallocate is successfull
        .IF eax != 0
            mov edx, [ebx].pData
            mov ecx, [ebx].dwSize
            mov eax, dwData
            mov DWORD ptr [edx + ecx * (sizeof DWORD)], eax
            inc [ebx].dwSize
        .ENDIF
    .ENDIF
    
    assume ebx:nothing
    ret
Vector__push_back ENDP

Vector__is_eq PROC uses ebx ecx edx esi edi, pThis: ptr Vector, pVec: ptr Vector
    mov ebx, pThis
    assume ebx: ptr Vector
    mov edx, pVec
    assume edx: ptr Vector
    
    mov ecx, [ebx].dwSize
    .IF [edx].dwSize != ecx
        mov eax, 0
        ret
    .ELSEIF ecx == 0
        mov eax, 1
        ret
    .ELSE
        mov ebx, [ebx].pData
        mov edx, [edx].pData
        assume ebx: DWORD
        assume edx: DWORD
        .REPEAT
            dec ecx
            mov esi, [ebx + ecx * (sizeof DWORD)]
            mov edi, [edx + ecx * (sizeof DWORD)]
            .IF esi != edi
                mov eax, 0
                ret
            .ENDIF
        .UNTIL ecx == 0
    .ENDIF
    
    mov eax, 1              
    
    assume ebx:nothing
    assume edx:nothing
    ret
Vector__is_eq ENDP

Vector__free PROC uses ebx, pThis: ptr Vector
    mov ebx, pThis
    assume ebx: ptr Vector
    mov ebx, [ebx].pData
    .IF ebx == 0
        ret
    .ENDIF
    assume ebx:nothing
    invoke crt_free, ebx
    ret
Vector__free ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public methods with public functions   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_Vector_New_constructor_base_start MACRO 
    invoke _Vector__constructor_base
    .IF eax == 0
        ret
    .ENDIF
    mov ebx, eax
    assume ebx: ptr Vector
ENDM

_Vector_New_constructor_base_end MACRO
    mov eax, ebx
    assume ebx:nothing
ENDM


PUBLIC Vector_New_Empty
Vector_New_Empty PROC
    _Vector_New_constructor_base_start
    
    invoke crt_malloc, 0
    .IF eax == 0
        invoke crt_free, ebx
        ret
    .ENDIF
    mov [ebx].pData, eax
    
    _Vector_New_constructor_base_end
    ret 
Vector_New_Empty ENDP

PUBLIC Vector_New_Filled
Vector_New_Filled PROC uses ebx, dwSize: DWORD, dwData: DWORD
    _Vector_New_constructor_base_start
    
    mov eax, dwSize
    imul eax, sizeof DWORD
    invoke crt_malloc, eax
    .IF eax == 0
        invoke crt_free, ebx
        ret
    .ENDIF
    mov [ebx].pData, eax
    mov eax, dwSize
    mov [ebx].dwSize, eax
    mov [ebx].dwCapacity, eax
    mov eax, ebx
    
    invoke _Vector__fill, ebx, dwData
    
    _Vector_New_constructor_base_end
    ret 
Vector_New_Filled ENDP

Vector_New_Copy PROC uses ebx ecx edx edi esi, pVec: ptr Vector
    _Vector_New_constructor_base_start
    
    mov edx, pVec
    assume edx: ptr Vector
    mov ecx, [edx].dwSize
    imul ecx, sizeof DWORD
    
    invoke crt_malloc, ecx
    mov edx, pVec
    .IF eax == 0
        invoke crt_free, ebx
        ret
    .ENDIF
    mov [ebx].pData, eax
    mov eax, [edx].dwSize
    mov [ebx].dwSize, eax
    mov [ebx].dwCapacity, eax
    
    mov ecx, [edx].dwSize
    mov edi, [ebx].pData
    mov esi, [edx].pData
    
    .IF ecx != 0
        .REPEAT
            dec ecx
            mov eax, [esi + ecx * (sizeof DWORD)]
            mov DWORD ptr [edi + ecx * (sizeof DWORD)], eax
        .UNTIL ecx == 0
    .ENDIF
    
    assume edx:nothing
    _Vector_New_constructor_base_end
    ret 
Vector_New_Copy ENDP

Vector_New_Move PROC uses ebx edx, pVec: ptr Vector
    _Vector_New_constructor_base_start
    
    mov edx, pVec
    assume edx: ptr Vector
    mov eax, [edx].pData
    mov [ebx].pData, eax
    mov [edx].pData, 0
    mov eax, [edx].dwSize
    mov [ebx].dwSize, eax
    mov [edx].dwSize, 0
    mov eax, [edx].dwCapacity
    mov [ebx].dwCapacity, eax
    mov [edx].dwCapacity, 0
    
    _Vector_New_constructor_base_end
    assume edx:nothing
    ret 
Vector_New_Move ENDP

PUBLIC Vector_Free
Vector_Free PROC uses ebx, pThis: ptr Vector
    mov ebx, pThis
    .IF ebx == 0
        ret
    .ENDIF
    assume ebx: ptr Vector
    
    mov eax, [ebx].pVTable
    invoke Vector_free_t PTR [eax + VectorVTable.free], ebx
    invoke crt_free, ebx
    
    assume ebx:nothing
    ret
Vector_Free ENDP

END
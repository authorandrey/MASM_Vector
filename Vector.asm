.386
.model flat, stdcall
option casemap:none
include \masm32\include\msvcrt.inc
includelib \masm32\lib\msvcrt.lib
include .\Vector.inc

.data
    PUBLIC Vector_vt
    Vector_vt VectorVTable <Vector__get_at, Vector__get_data, Vector__get_size, Vector_capacity, Vector__push_back, Vector__free>
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
        mov eax, edx                   ; eax = geometric
    .ENDIF
    
    mov ecx, dwNewSize
    cmp eax, ecx
    .IF CARRY?                         ; unsigned eax < dwNewSize
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

Vector__free PROC uses ebx, pThis: ptr Vector
    mov ebx, pThis
    assume ebx: ptr Vector
    mov ebx, [ebx].pData
    assume ebx:nothing
    invoke crt_free, ebx
    ret
Vector__free ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public methods with public functions   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PUBLIC Vector_New_Filled
Vector_New_Filled PROC uses ebx, dwSize: DWORD, dwData: DWORD
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
    
    mov eax, ebx
    assume ebx:nothing
    ret 
Vector_New_Filled ENDP

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
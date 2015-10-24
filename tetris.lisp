;Tipo Acção
(defun cria-accao(coluna peça)
	(cons coluna peça))

(defun accao-coluna(accao)
	(car accao))

(defun accao-peca(accao)
	(cdr accao))

;Tipo Tabuleiro

(defun cria-tabuleiro()
	(make-array (list 18 10)))

;http://stackoverflow.com/questions/7912232/how-do-you-copy-an-array-in-common-lisp
(defun copia-tabuleiro (array &key
                   (element-type (array-element-type array))
                   (fill-pointer (and (array-has-fill-pointer-p array)
                                      (fill-pointer array)))
                   (adjustable (adjustable-array-p array)))
  "Returns an undisplaced copy of ARRAY, with same fill-pointer and
adjustability (if any) as the original, unless overridden by the keyword
arguments."
  (let* ((dimensions (array-dimensions array))
         (new-array (make-array dimensions
                                :element-type element-type
                                :adjustable adjustable
                                :fill-pointer fill-pointer)))
    (dotimes (i (array-total-size array))
      (setf (row-major-aref new-array i)
            (row-major-aref array i)))
    new-array))

(defun tabuleiro-preenchido-p(tabuleiro linha coluna)
  (if (eql (aref tabuleiro linha coluna) NIL) NIL T))

(defun tabuleiro-altura-coluna(tabuleiro coluna)
	(let ((altura 17))
    (loop for i from 17 downto 0 do
	    (if (aref tabuleiro i coluna) (return)
	      (decf altura)))
    altura))

(defun tabuleiro-linha-completa-p(tabuleiro linha)
  (let ((completa T))
		(loop for i from 0 upto 9 do
		  (if (eq (aref tabuleiro linha i) NIL) (progn (setf completa NIL) (return))))
  	completa))

(defun tabuleiro-preenche!(tabuleiro linha coluna)
  (if (and (>= linha 0)(< linha 18)
       		 (>= coluna 0)(< coluna 10))
      (setf (aref tabuleiro linha coluna) T)))

;Loop até linha 16 porque a 17 está sempre
;a NIL ou caso contrário o jogo termina
(defun tabuleiro-remove-linha!(tabuleiro linha)
  (loop for l from linha upto 16 do
  	(loop for c from 0 upto 9 do
    	(setf (aref tabuleiro l c)
            (aref tabuleiro (+ l 1) c)))))

(defun tabuleiro-topo-preenchido-p(tabuleiro)
  (loop for coluna from 0 upto 9 do
    (if (tabuleiro-preenchido-p tabuleiro 17 coluna) (return T))))

(defun tabuleiros-iguais-p(tabuleiro1 tabuleiro2)
  (eq tabuleiro1 tabuleiro2))

;Just this!?
(defun tabuleiro->array(tabuleiro)
  (copia-tabuleiro tabuleiro))

(defun array->tabuleiro(array)
  (copia-tabuleiro array))
;-----------

;Tipo Estado

(defstruct estado
  pontos
  pecas-por-colocar
  pecas-colocadas
  Tabuleiro
)

(defun copia-estado(estado)
  (make-estado :pontos (estado-pontos estado)
    :pecas-por-colocar (estado-pecas-por-colocar estado)
      :pecas-colocadas (estado-pecas-colocadas estado)
      :Tabuleiro (estado-Tabuleiro estado)))

;Só para testar
;(defparameter *estadoteste* (make-estado
; :pontos 100
;  :pecas-por-colocar (list peca-i0 peca-l0 peca-j0)
;  :pecas-colocadas (list )
;  :Tabuleiro *tazbuleiro*))

(defun estados-iguais-p(estado1 estado2)
  (equalp estado1 estado2))

(defun estado-final-p(estado)
  (or (tabuleiro-topo-preenchido-p (estado-Tabuleiro estado))
      (null (estado-pecas-por-colocar estado))))

;Tipo Problema
(defstruct problema
  estado-inicial
  (solucao 'solucao)
  (accoes 'accoes)
  (resultado 'resultado)
  (custo-caminho 'custo-caminho)
)

;Só para testar
(defparameter *problemateste* (make-problema
 :estado-inicial 100))

;(funcall (problema-solucao *problemateste*) *estadoteste*)
(defun solucao(estado)
  (and (not (tabuleiro-topo-preenchido-p (estado-Tabuleiro estado)))
       (null (estado-pecas-por-colocar estado))))

;Fazer rotação matriz para usar na peça (aplicável a 2D arrays)
;http://rosettacode.org/wiki/Matrix_transposition#Common_Lisp
(defun mtp (A)
  (let* ((m (array-dimension A 0))
         (n (array-dimension A 1))
         (B (make-array `(,n ,m) :initial-element 0)))
    (loop for i from 0 below m do
          (loop for j from 0 below n do
                (setf (aref B j i)
                      (aref A i j))))
    B))

(defun reverse-array(array)
  (let ((reversed (make-array (list (array-dimension array 0)
                              (array-dimension array 1)))))
  (loop for c from 0 upto (- (array-dimension array 1) 1) do
  	(loop for l from 0 upto (- (array-dimension array 0) 1) do
    	(setf (aref reversed (- (- (array-dimension reversed 0) 1) l) c)
            (aref array l c))))
  reversed))

;limit: largurado do tabuleiro - largura da peça (10 - ?)
(defun accoes(estado)
  (let ((peca (car (estado-pecas-por-colocar estado)))
        (limit (- 10 (array-dimension (car (estado-pecas-por-colocar estado)) 1)))
        (lista-accoes (list )))
    (loop for i from 0 upto limit do
	    (push (cons i peca) lista-accoes)) ;lista acções para primeira rotação 
    
    (setf peca (reverse-array (mtp peca))) ;roda peça
    (setf limit (- 10 (array-dimension peca 1))) ;actualiza limit
    
    (if (not (equalp (car (estado-pecas-por-colocar estado)) peca)) ;se a rotação da peca não for igual à original continua
        (loop for i from 0 upto limit do
          (push (cons i peca) lista-accoes)
          (if (= i limit) ;chegou ao fim do ciclo
              (progn (setf peca (reverse-array (mtp peca))) ;roda peça
                     (if (equalp (car (estado-pecas-por-colocar estado)) peca);se a rotação da peca for igual à original sai do ciclo
                         (return)
                         (progn (setf limit (- 10 (cadr (array-dimensions peca)))) ;actualiza limit
                                (setf i -1))))))) ;i a 0 para fazer o ciclopara a nova rotação
    (reverse lista-accoes))) ;devolve lista de acções pela ordem correcta

(defun calcula-pontos(estado peca linha-inicial)
  (let ((tabuleiro (estado-Tabuleiro estado))
        (altura (- (array-dimension peca 0) 1))
        (nlinhas 0))
  ;ciclo para percorrer as linhas do tabuleiro (nº de linhas = altura da peça)
  (loop for i from 0 upto altura do
    (if (tabuleiro-linha-completa-p tabuleiro linha-inicial) ;se linha estiver completa
      (progn (tabuleiro-remove-linha! tabuleiro linha-inicial) ;remove linha
             (incf nlinhas)) ;e incrementa nº linhas removidas
      (incf linha-inicial))) ;caso contrário vê a linha acima
  
  (if (= nlinhas 1) ;cálculo de pontos
    (setf (estado-pontos estado) (+ (estado-pontos estado) 100))
    (if (= nlinhas 2)
      (setf (estado-pontos estado) (+ (estado-pontos estado) 300))
      (if (= nlinhas 3)
        (setf (estado-pontos estado) (+ (estado-pontos estado) 500))
        (if (= nlinhas 4)
          (setf (estado-pontos estado) (+ (estado-pontos estado) 800))))))))
      
  
(defun resultado(estado accao)
  (let ((novo-estado (copia-estado estado)) ;copia estado
        (coluna (car accao))                ;coluna onde a peça vai ser colocada
        (peca (cdr accao))                  ;estrutura da peça
        ;altura onde a peça vai ser colodada a partir da 1ª coluna
        (altura-max (tabuleiro-altura-coluna (estado-Tabuleiro estado) (car accao)))) 
    ;ciclo para descer a altura da peca se tiver elementos a NIL na 1ª coluna
    (loop for l from 0 upto (- (array-dimension peca 0) 1) do
      (if (not (aref peca l 0)) ;se elemento da peça for NIL
        (decf altura-max) ;decrementa altura
        (return)))
    
    ;ciclo para descer a altura da peca se tiver elementos a NIL nas restantes coluna (desde 2ª à última)
    (loop for c from (+ 1 coluna) upto (- (+ coluna (array-dimension peca 1)) 1) do
      (if (> (tabuleiro-altura-coluna (estado-Tabuleiro novo-estado) c) altura-max) ;se topo da coluna for maior que o topo da anterior
        (progn (setf altura-max (tabuleiro-altura-coluna (estado-Tabuleiro novo-estado) c)) ;actualiza altura 
              ;ciclo para descer a altura da peca se tiver elementos a NIL na coluna respectiva (- c coluna)
              (loop for l from 0 upto (- (array-dimension peca 0) 1) do
                (if (not (aref peca l (- c coluna))) ;se elemento da peça for NIL
                  (decf altura-max) ;decrementa altura
                  (return))))))
    
    ;ciclo para preencher o tabuleiro com a peça
   	(loop for l from altura-max upto (min 17 (- (+ altura-max (array-dimension peca 0)) 1)) do
	    (loop for c from coluna upto (- (+ coluna (array-dimension peca 1)) 1) do
        (if (aref peca (- l altura-max) (- c coluna))
          (setf (aref (estado-Tabuleiro novo-estado) l c) (aref peca (- l altura-max) (- c coluna))))))
    (push (car (estado-pecas-por-colocar novo-estado)) (estado-pecas-colocadas novo-estado)) ;actualiza lista das pecas-colocadas
    (pop (estado-pecas-por-colocar novo-estado)) ;retira a peça colocada da lista das peças por-colocar
    (if (not (tabuleiro-topo-preenchido-p (estado-Tabuleiro novo-estado))) ;se não foi game over
     (calcula-pontos novo-estado peca altura-max)) ;calcula pontos
    novo-estado))
	
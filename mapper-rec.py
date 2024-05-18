#!/usr/bin/env python3

import sys

for line in sys.stdin:
    line = line.strip()  # quitar espacios en blanco al inicio y final de la línea

    if line[0] == "a":  # quitar la cabecera que comienza por 'a'
        continue

    words = line.split(",")  # separar los campos por ','

    wordFinal = []  # array de campos finales (incluidos los separados por ',')
    union = ""  # string temporal para ir juntando las partes de los campos
    for word in words:  # para todos los campos
        if word[0] == "\"":  # si el campo comienza por '"'
            union = word.replace(word[0], "")  # se agrega a unión y se quita la '"' y continua
            continue
        if union != "" and word[len(word) - 1] != "\"":  # si ya se tienen las partes y no se ha llegado al final
            union = union + word
        elif union != "" and word[len(word) - 1] == "\"":  # si ya se tienen partes y se ha llegado al final
            word = word.replace('\"', "")
            wordFinal.append(union + word)
            union = ""  # se borra unión para el próximo
        else:
            wordFinal.append(word)  # en caso contrario se agrega

    wordsNoWhite = wordFinal[13].replace(" ", "_")  # cambia los espacios en blanco por "_"
    print('%s\t%s' % (wordsNoWhite, 1))  # se generan las tuplas con el campo 13.

; ahk: console
class Venn {

    requires() {
        return [Ansi, OptParser, System, String]
    }

    static opts := Venn.setDefaults()
    static OP_NAME
            := [ "'Intersection' A:( (*) ):B"
            , "'Union' A:(*(*)*):B"
            , "'Symmetric Difference' A:(*( )*):B"
            , "'Relative Complement' A:(*( ) ):B" ]

    setDefaults() {
        dv := { a: false
                , b: true
                , compare_at: 1
                , enc_A: "cp1252"
                , enc_B: "cp1252"
                , h: false
                , i: -1
                , k: false
                , l: -1
                , op: ""
                , output: false
                , output_file: ""
                , s: false
                , set_A: ""
                , set_B: ""
                , t: -1
                , u: false
                , v: false
                , version: false }

        Venn.opts := dv
    }

    loadFile(ByRef target, file_name, enc="utf-8") {
        FileGetSize size, %file_name%
        file := FileOpen(file_name, "r`n", enc)
        content := file.read(size)
        file.close()
        sort_option := (Venn.opts.i = true ? "" : "C")
        Sort content, %sort_option%
        target := []
        loop Parse, content, % "`n", % Chr(26)  ; NOWARN
        {
            if (!Venn.opts.b || A_LoopField.trimAll() != "") {
                target.insert(A_LoopField)
            }
        }
    }

    ; TODO: Refactor!
    doOperation(op, file_A, file_B) {
        ; Handle --ignore-all option
        if (Venn.opts.a) {
            if (Venn.opts.i != 0) {
                Venn.opts.i := true
            }
            if (Venn.opts.l != 0) {
                Venn.opts.l := true
            }
            if (Venn.opts.t != 0) {
                Venn.opts.t := true
            }
        }

        Venn.loadFile(A, file_A, Venn.opts.enc_A)
        Venn.loadFile(B, file_B, Venn.opts.enc_B)

        i_A := A.minIndex()
        i_B := B.minIndex()

        VarSetCapacity(HIGH, 4, 0xFF)
        A.push(HIGH)
        B.push(HIGH)

        try {
            if (Venn.opts.output != "") {
                if (Venn.opts.k) {
                    Venn.opts.output_file := FileOpen(Venn.opts.output, "a")
                } else {
                    Venn.opts.output_file := FileOpen(Venn.opts.output, "w")
                }
            }

            n := 0
            while (i_A < A.maxIndex() || i_B < B.maxIndex()) {
                while (i_A < A.maxIndex() && Venn.compare(A[i_A], B[i_B]) < 0) {
                    if (op = 2 || op = 3 || op = 4) {
                        Venn.output(A[i_A], n, "A")
                    }
                    i_A++
                }
                while (i_B < B.maxIndex() && Venn.compare(B[i_B], A[i_A]) < 0) {
                    if (op = 2 || op = 3) {
                        Venn.output(B[i_B], n, "B")
                    }
                    i_B++
                }
                while ((i_A < A.maxIndex() || i_B < B.maxIndex())
                        && Venn.compare(A[i_A], B[i_B]) = 0) {
                    if (op = 1 || op = 2) {
                        Venn.output(A[i_A], n, "A")
                        Venn.output(B[i_B], n, "B")
                    }
                    i_A++
                    if (op != 4) {
                        i_B++
                    }
                }
            }
        } finally {
            if (Venn.opts.output_file != "") {
                Venn.opts.output_file.close()
            }
        }

        return n
    }

    output(pValue, ByRef count, source="") {

        static last_value = ""


        if (Venn.opts.u && (Venn.opts.i = true
                ? (pValue = last_value)
                : (pValue == last_value))) {
            return
        }

        if (Venn.opts.output != "") {
            Venn.opts.output_file.writeLine((Venn.opts.s
                    ? "(" source ") "
                    : "") pValue)
        } else {
            Ansi.write((Venn.opts.s ? "(" source ") " : "") pValue "`n")
        }
        last_value := pValue
        count++
    }

    compare(elem_A, elem_B) {
        if (Venn.opts.l = true && Venn.opts.t = true) {
            elem_A := elem_A.trimAll()
            elem_B := elem_B.trimAll()
        } else if (Venn.opts.l = true) {
            elem_A := elem_A.trimLeft()
            elem_B := elem_B.trimLeft()
        } else if (Venn.opts.t = true) {
            elem_A := elem_A.trimRight()
            elem_B := elem_B.trimRight()
        }


        return elem_A.compare(elem_B, (Venn.opts.i = true
                ? String.COMPARE_AS_STRING
                : String.COMPARE_AS_CASE_SENSITIVE_STRING))
    }

    ; TODO: Refactor!
    cli() {
        op := new OptParser("venn [options] "
                . "--operation=< is | un | sd | rc > -A <file> -B <file>")
        op.add(new OptParser.Group("General options"))
        op.add(new OptParser.Boolean("h", "help", Venn.opts
                , "h", "This help"
                , OptParser.OPT_HIDDEN))
        op.add(new OptParser.Boolean("a", "ignore-all", Venn.opts
                , "a", "Ignore leading and trailing spaces`; ignore case"
                ,, false))
        op.add(new OptParser.Boolean("i", "ignore-case", Venn.opts
                , "i", "Ignore case"
                , OptParser.OPT_NEG, -1))
        op.add(new OptParser.Boolean("l", "ignore-leading-spaces", Venn.opts
                , "l", "Ignore leading spaces"
                , OptParser.OPT_NEG, -1))
        op.add(new OptParser.Boolean("t", "ignore-trailing-spaces", Venn.opts
                , "t", "Ignore trailing spaces"
                , OptParser.OPT_NEG, -1))
        op.add(new OptParser.Boolean("b", "ignore-blank-lines", Venn.opts
                , "b", "Ignore blank line (default)"
                , OptParser.OPT_NEG, true))
        op.add(new OptParser.Boolean("u", "unique", Venn.opts
                , "u", "Only keep the first of multiple identical lines"))
        op.add(new OptParser.Boolean("s", "source", Venn.opts
                , "s", "Print source (A/B) in results"))
        op.add(new OptParser.Boolean("v", "verbose", Venn.opts
                , "v", "Verbose output"))
        op.add(new OptParser.Boolean(0, "version", Venn.opts
                , "version", "Version info"))
        op.add(new OptParser.String(0, "enc-A", Venn.opts
                , "enc_A", "encoding", "Encoding of file A"
                , OptParser.OPT_ARG,, Venn.opts.enc_A))
        op.add(new OptParser.String(0, "enc-B", Venn.opts
                , "enc_B", "encoding", "Encoding fo file B"
                , OptParser.OPT_ARG,, Venn.opts.enc_B))
        op.add(new Optparser.Group("`nSets"))
        op.add(new OptParser.String("A", "", Venn.opts
                , "set_A", "file", "File name to use as set A"
                , OptParser.OPT_ARG))
        op.add(new OptParser.String("B", "", Venn.opts
                , "set_B", "file", "File name to use as set B"
                , OptParser.OPT_ARG))
        op.add(new OptParser.Group("`nOperations"))
        op.add(new OptParser.Callback(0, "operation", Venn.opts
                , "op", "operation_cb", "operation"
                , [ "Select an operation to perform"
                . " (the '*' represents the result set):"
                , ". is: " Venn.OP_NAME[1]
                , ". un: " Venn.OP_NAME[2]
                , ". sd: " Venn.OP_NAME[3]
                , ". rc: " Venn.OP_NAME[4] ]))
        op.add(new OptParser.Group("`nOutput options`n    "
                . "Output will be written to console by default`n"))
        op.add(new OptParser.String("o", "", Venn.opts
                , "output", "file", "Write matching lines to file"
                , OptParser.OPT_ARG))
        op.add(new OptParser.Boolean(0, "keep-file", Venn.opts
                , "k", "Append to file instead of overwriting it"
                , false))
        return op
    }

    run(args) {
        Venn.setDefaults()
        RC := 0

        try {
            op := Venn.cli()
            args := op.parse(args)
            if (args.minIndex() != "") {
                throw Exception("error: Invalid argument(s): "
                        . Arrays.toString(args, "; "))
            }
            if (Venn.opts.h) {
                Ansi.writeLine(op.usage())
            } else if (Venn.opts.version) {
                G_VERSION_INFO := { NAME: "AHK venn version v0.0.0"
                        , ARCH: "x" (A_PtrSize = 4 ? "86" : "64")
                        , BUILD: A_YYYY A_MM A_DD A_Hour A_Min }
                #Include *i %A_ScriptDir%\.versioninfo
                Ansi.writeLine(G_VERSION_INFO.NAME
                        . "/" G_VERSION_INFO.ARCH
                        . "-b" G_VERSION_INFO.BUILD)
            } else {
                if (!FileExist(Venn.opts.set_A)) {
                    throw Exception("error: Argument -A is an invalid file "
                            . "or missing")
                }
                if (!FileExist(Venn.opts.set_B)) {
                    throw Exception("error: Argument -B is an invalid file "
                            . "or missing")
                }
                Venn.opts.output := Venn.opts.output.trimAll()
                if (Venn.opts.v) {
                    if (Venn.opts.i = true || Venn.opts.a = true) {
                        Ansi.write("Ignoring case`n")
                    } else {
                        Ansi.write("Case sensitive`n")
                    }
                    if (Venn.opts.l = true || Venn.opts.a = true) {
                        Ansi.write("Ignoring leading spaces`n")
                    }
                    if (Venn.opts.t = true || Venn.opts.a = true) {
                        Ansi.write("Ignoring trailing spaces`n")
                    }
                    if (Venn.opts.b) {
                        Ansi.write("Ignoring blank lines`n")
                    }
                    if (Venn.opts.u) {
                        Ansi.write("Printing no duplicates`n")
                    }
                    Ansi.write("Set 'A' is " Venn.opts.set_A
                            . " with encoding " Venn.opts.enc_A "`n")
                    Ansi.write("Set 'B' is " Venn.opts.set_B
                            . " with encoding " Venn.opts.enc_B "`n")
                    Ansi.write("Performing operation "
                            . Venn.OP_NAME[Venn.opts.op] "`n")
                    if (Venn.opts.output.trimAll() != "") {
                        if (Venn.opts.k) {
                            Ansi.write("Appending to file "
                                    . Venn.opts.output "`n")
                        } else {
                            Ansi.write("Overwrting file "
                                    . Venn.opts.output "`n")
                        }
                    }
                }

                RC := Venn.doOperation(Venn.opts.op
                        , Venn.opts.set_A, Venn.opts.set_B)
            }
        } catch _ex {
            Ansi.write(_ex.message "`n")
            Ansi.write(op.usage() "`n")
        }

        return RC
    }
}

operation_cb(pValue, no_opt="") {
    if (pValue = "is") {
        return 1
    } else if (pValue = "un") {
        return 2
    } else if (pValue = "sd") {
        return 3
    } else if (pValue = "rc") {
        return 4
    } else {
        throw Exception("Invalid operation: " pValue)
    }
}

#NoEnv                                              ; NOTEST-BEGIN
SetBatchLines -1

#Include <ansi\ansi>
#Include <optparser\optparser>
#Include <system\system>
#Include <string\string>

main:
    _main := new Logger("app.venn.main")
exitapp _main.exit(Venn.run(System.vArgs))        ; NOTEST-END
; vim:tw=0:ts=4:sts=4:sw=4:et:ft=autohotkey:nobomb

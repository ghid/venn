; ahk: console
class Venn {

    requires() {
        return [Ansi, OptParser, System, String, Arrays]
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
                , version: false
                , count: 0}

        Venn.opts := dv
    }

    loadFileIntoArray(fileName, encoding="utf-8") {
        FileGetSize sizeOfInputFileInBytes, %fileName%
        inputFile := FileOpen(fileName, "r`n", encoding)
        contentOfInputFile := inputFile.read(sizeOfInputFileInBytes)
        inputFile.close()
        sortOption := (Venn.opts.i = true ? "" : "C")
        Sort contentOfInputFile, %sortOption%
        target := []
        loop Parse, contentOfInputFile, % "`n", % Chr(26)  ; NOWARN
        {
            if (!Venn.opts.b || A_LoopField.trimAll() != "") {
                target.push(A_LoopField)
            }
        }
        return target
    }

    doOperation(op, fileA, fileB, compareAsType=0) {
        Venn.handleIgnoreAll()
        A := Venn.loadFileIntoArray(fileA, Venn.opts.enc_A)
        B := Venn.loadFileIntoArray(fileB, Venn.opts.enc_B)
        try {
            VennData.includeSource := Venn.opts.s
            Venn.handleOutput()
            resultSet := Arrays.venn(A, B, op, Venn.handleIgnoreCase())
            while (A_Index <= resultSet.maxIndex()) {
                count := Venn.output(resultSet[A_Index])
            }
        } finally {
            if (Venn.opts.output_file != "") {
                Venn.opts.output_file.close()
            }
        }
        return count
    }

    handleOutput() {
        if (Venn.opts.output != "") {
            if (Venn.opts.k) {
                Venn.opts.output_file := FileOpen(Venn.opts.output, "a")
            } else {
                Venn.opts.output_file := FileOpen(Venn.opts.output, "w")
            }
        }
    }

    handleIgnoreCase() {
        if (Venn.opts.i == true) {
            return String.COMPARE_AS_STRING
        } else {
            return String.COMPARE_AS_CASE_SENSITIVE_STRING
        }
    }

    handleIgnoreAll() {
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
    }

    output(value) {
        static last_value = ""

        if (Venn.opts.u && (Venn.opts.i = true
                ? (value = last_value)
                : (value == last_value))) {
        } else {
            if (Venn.opts.output != "") {
                Venn.opts.output_file.writeLine(value)
            } else {
                Ansi.write(value "`n")
            }
            last_value := value
            Venn.opts.count++
        }
        return Venn.opts.count
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
        returnCode := 0
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
                global G_VERSION_INFO
                Ansi.writeLine(G_VERSION_INFO.NAME
                        . "/" G_VERSION_INFO.ARCH
                        . "-" G_VERSION_INFO.BUILD)
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
                VennData.includeSource := Venn.opts.s
                returnCode := Venn.doOperation(Venn.opts.op
                        , Venn.opts.set_A, Venn.opts.set_B)
            }
        } catch _ex {
            Ansi.write(_ex.message "`n")
            Ansi.write(op.usage() "`n")
        }
        return returnCode
    }
}

operation_cb(operation, noOption="") {
    if (operation = "is") {
        return 1
    } else if (operation = "un") {
        return 2
    } else if (operation = "sd") {
        return 3
    } else if (operation = "rc") {
        return 4
    } else {
        throw Exception("Invalid operation: " operation)
    }
}

#NoEnv ; notest-begin
SetBatchLines -1

#Include <app>
#Include <ansi>
#Include <console>
#Include <math>
#Include <arrays>
#Include <optparser>
#Include <object>
#Include <system>
#Include <string>
#Include *i %A_ScriptDir%\.versioninfo

main:
    App.checkRequiredClasses(Venn)
exitapp Venn.run(A_Args) ; notest-end

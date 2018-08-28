class Venn {

    static opts := Venn.set_defaults() 
    static OP_NAME := [ "'Intersection' A:( (*) ):B"
                      , "'Union' A:(*(*)*):B"
                      , "'Symmetric Difference' A:(*( )*):B"
                      , "'Relative Complement' A:(*( ) ):B" ]

    /*
    * Method:  set_default_opts
    *          initialize options.
    */
    set_defaults() {
        dv := { a: false
            , b: true
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
    
    /*
    * Method:  load_file
    *          Load content of a file into a list.
    *
    * Parameter:
    *          target - The list to receive the content of the file.
    *          file_name - Name of the file.
    *          enc - Encoding (default: UTF-8)
    */
    load_file(ByRef target, file_name, enc = "utf-8") {
        _log := new Logger("app.venn." A_ThisFunc)

        if (_log.Logs(Logger.Input)) {
            _log.Input("file_name", file_name)
            _log.Input("enc", enc)
        }

        FileGetSize size, %file_name%
        file := FileOpen(file_name, "r`n", enc)
        if (_log.Logs(Logger.Finest)) {
            _log.Finest("size", size)
            _log.Finest("file", file)
        }
        content := file.Read(size)
        if (_log.Logs(Logger.ALL)) {
            _log.All("content:`n" LoggingHelper.HexDump(&content, 0, size * (A_IsUnicode ? 2 : 1)))
        }
        file.Close()

        sort_option := (Venn.opts.i = true ? "" : "C")
        if (_log.Logs(Logger.Finest)) {
            _log.Finest("Venn.opts.i", Venn.opts.i)
            _log.Finest("Venn.opts.b", Venn.opts.b)
            _log.Finest("sort_option = " sort_option)
        }
        Sort content, %sort_option%
        target := []
        loop Parse, content, % "`n", % Chr(26)  ; NOWARN
        {
            if (!Venn.opts.b || A_LoopField.Trim() <> "") {
                target.Insert(A_LoopField)
            }
        }

        if (_log.Logs(Logger.Output)) {
            _log.Output("target", target)
            if (_log.Logs(Logger.ALL)) {
                _log.ALL("target:`n" LoggingHelper.Dump(target))
            }
        }

        return _log.Exit()
    }

    /*
    * Method:  do_operation
    *          Perform the desired set operation.
    *
    * Parameter:
    *          op - Operation to perform
    *          file_A - Name of file A
    *          file_B - Name of file B
    *
    * Returns:
    *          Lenght of the result set.
    */
    do_operation(op, file_A, file_B) {
        _log := new Logger("class." A_ThisFunc)

        if (_log.Logs(Logger.Input)) {
            _log.Input("op", op)
            _log.Input("file_A", file_A)
            _log.Input("file_B", file_B)
        }

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

        Venn.load_file(A, file_A, Venn.opts.enc_A)
        Venn.load_file(B, file_B, Venn.opts.enc_B)

        i_A := A.MinIndex()
        i_B := B.MinIndex()
        if (_log.Logs(Logger.Finest)) {
            _log.Finest("Venn.opts.a", Venn.opts.a)
            _log.Finest("Venn.opts.i", Venn.opts.i)
            _log.Finest("Venn.opts.l", Venn.opts.l)
            _log.Finest("Venn.opts.t", Venn.opts.t)
            _log.Finest("i_A", i_A)
            _log.Finest("i_B", i_B)
            _log.Finest("A.MaxIndex()", A.MaxIndex())
            _log.Finest("B.MaxIndex()", B.MaxIndex())
        }

        VarSetCapacity(HIGH, 4, 0xFF)
        A.Insert(HIGH)
        B.Insert(HIGH)

        try {
            if (Venn.opts.output <> "") {
                if (Venn.opts.k) {
                    Venn.opts.output_file := FileOpen(Venn.opts.output, "a")
                } else {
                    Venn.opts.output_file := FileOpen(Venn.opts.output, "w")
                }
            }

            n := 0
            while (i_A < A.MaxIndex() || i_B < B.MaxIndex()) {
                while (i_A < A.MaxIndex() && Venn.compare(A[i_A], B[i_B]) < 0) {
                    if (_log.Logs(Logger.Detail)) {
                        _log.Detail("A[" i_A "]:" A[i_A] " < B[" i_B "]:" B[i_B])
                    }
                    if (op = 2 || op = 3 || op = 4) {
                        Venn.output(A[i_A], n, "A")
                    }
                    i_A++
                }
                while (i_B < B.MaxIndex() && Venn.compare(B[i_B], A[i_A]) < 0) {
                    if (_log.Logs(Logger.Detail)) {
                        _log.Detail("A[" i_A "]:" A[i_A] " > B[" i_B "]:" B[i_B])
                    }
                    if (op = 2 || op = 3) {
                        Venn.output(B[i_B], n, "B")
                    }
                    i_B++
                }
                while ((i_A < A.MaxIndex() || i_B < B.MaxIndex()) && Venn.compare(A[i_A], B[i_B]) = 0) {
                    if (_log.Logs(Logger.Detail)) {
                        _log.Detail("A[" i_A "]:" A[i_A] " = B[" i_B "]:" B[i_B])
                    }
                    if (op = 1 || op = 2) {
                        Venn.output(A[i_A], n, "A")
                        Venn.output(B[i_B], n, "B")
                    }
                    i_A++
                    if (op <> 4) {
                        i_B++
                    }
                }
            }
        } finally {
            if (Venn.opts.output_file <> "") {
                Venn.opts.output_file.Close()
            }
        }

        return _log.Exit(n)
    }

    /*
    * Method:  output
    *          Handle output of results.
    *
    * Parameter:
    *          pValue - The value to output.
    *          count - counter of results.
    *          source - Origin set of the value (A/B).
    */
    output(pValue, ByRef count, source = "") {
        _log := new Logger("class." A_ThisFunc)

        if (_log.Logs(Logger.Input)) {
            _log.Input("pValue", pValue)
            _log.Input("count", count)
            _log.Input("source", source)
        }

        static last_value = ""
        if (_log.Logs(Logger.Finest)) {
            _log.Finest("last_value", last_value)
            _log.Finest("Venn.opts.u", Venn.opts.u)
            _log.Finest("Venn.opts.i", Venn.opts.i)
        }

        if (Venn.opts.u && (Venn.opts.i = true ? (pValue = last_value) : (pValue == last_value))) {
            if (_log.Logs(Logger.Detail)) {
                _log.Detail("Discard value from result: " pValue)
            }
            return _log.Exit()
        }

        if (_log.Logs(Logger.Detail)) {
            _log.Detail("Add value to result: " pValue)
        }
        if (Venn.opts.output <> "") {
            Venn.opts.output_file.WriteLine((Venn.opts.s ? "(" source ") " : "") pValue)
        } else {
            Ansi.Write((Venn.opts.s ? "(" source ") " : "") pValue "`n")
        }
        last_value := pValue
        count++

        if (_log.Logs(Logger.Output)) {
            _log.Output("count", count)
        }

        return _log.Exit()
    }

    /*
    * Method:  compare
    *          Compare two values.
    *
    * Parameter:
    *          elem_A - First value.
    *          elem_B - Second value.
    *
    * Remarks:
    *          All values are trimmed befor comparison.
    *          The comparison is string-based.
    *
    * Returns:
    *          -1 - if elem_A < elem_B
    *          0 - if elem_A = elem_B
    *          +1 - if elem_A > elem_B
    */
    compare(elem_A, elem_B) {
        _log := new Logger("app.venn." A_ThisFunc)

        if (_log.Logs(Logger.Input)) {
            _log.Input("elem_A", elem_A)
            _log.Input("elem_B", elem_B)
        }

        if (_log.Logs(Logger.Finest)) {
            _log.Finest("Venn.opts.l", Venn.opts.l)
            _log.Finest("Venn.opts.t", Venn.opts.t)
        }
        if (Venn.opts.l = true && Venn.opts.t = true) {
            elem_A := elem_A.Trim(String.TRIM_ALL)
            elem_B := elem_B.Trim(String.TRIM_ALL)	
        } else if (Venn.opts.l = true) {
            elem_A := elem_A.Trim(String.TRIM_LEFT)
            elem_B := elem_B.Trim(String.TRIM_LEFT)
        } else if (Venn.opts.t = true) {
            elem_A := elem_A.Trim(String.TRIM_RIGHT)
            elem_B := elem_B.Trim(String.TRIM_RIGHT)
        }

        if (_log.Logs(Logger.Finest)) {
            _log.Finest("Venn.opts.i", Venn.opts.i)
        }

        return _log.Exit(elem_A.Compare(elem_B, (Venn.opts.i = true ? String.COMPARE_AS_STRING : String.COMPARE_AS_CASE_SENSITIVE_STRING)))
    }

    /*
     * Method:  cli
     *          Provide option parser.
     *
     * Returns:
     *          OptParser object.
     */
    cli() {
        _log := new Logger("class." A_ThisFunc)

        op := new OptParser("venn [options] --operation=< is | un | sd | rc > -A <file> -B <file>")
        op.Add(new OptParser.Group("General options"))
        op.Add(new OptParser.Boolean("h", "help", Venn.opts, "h", "This help", OptParser.OPT_HIDDEN))
        op.Add(new OptParser.Boolean("a", "ignore-all", Venn.opts, "a", "Ignore leading and trailing spaces`; ignore case",, false))
        op.Add(new OptParser.Boolean("i", "ignore-case", Venn.opts, "i", "Ignore case", OptParser.OPT_NEG, -1))
        op.Add(new OptParser.Boolean("l", "ignore-leading-spaces", Venn.opts, "l", "Ignore leading spaces", OptParser.OPT_NEG, -1))
        op.Add(new OptParser.Boolean("t", "ignore-trailing-spaces", Venn.opts, "t", "Ignore trailing spaces", OptParser.OPT_NEG, -1))
        op.Add(new OptParser.Boolean("b", "ignore-blank-lines", Venn.opts, "b", "Ignore blank line (default)", OptParser.OPT_NEG, true))
        op.Add(new OptParser.Boolean("u", "unique", Venn.opts, "u", "Only keep the first of multiple identical lines"))
        op.Add(new OptParser.Boolean("s", "source", Venn.opts, "s", "Print source (A/B) in results"))
        op.Add(new OptParser.Boolean("v", "verbose", Venn.opts, "v", "Verbose output"))
        op.Add(new OptParser.Boolean(0, "version", Venn.opts, "version", "Version info"))
        op.Add(new OptParser.String(0, "enc-A", Venn.opts, "enc_A", "encoding", "Encoding of file A", OptParser.OPT_ARG,, Venn.opts.enc_A))
        op.Add(new OptParser.String(0, "enc-B", Venn.opts, "enc_B", "encoding", "Encoding fo file B", OptParser.OPT_ARG,, Venn.opts.enc_B))
        op.Add(new Optparser.Group("`nSets"))
        op.Add(new OptParser.String("A", "", Venn.opts, "set_A", "file", "File name to use as set A", OptParser.OPT_ARG))
        op.Add(new OptParser.String("B", "", Venn.opts, "set_B", "file", "File name to use as set B", OptParser.OPT_ARG))
        op.Add(new OptParser.Group("`nOperations"))
        op.Add(new OptParser.Callback(0, "operation", Venn.opts, "op", "op_cb", "operation"
                , [ "Select an operation to perform (the '*' represents the result set):"
                  , ". is: " Venn.OP_NAME[1]
                  , ". un: " Venn.OP_NAME[2]
                  , ". sd: " Venn.OP_NAME[3]
                  , ". rc: " Venn.OP_NAME[4] ]))
        op.Add(new OptParser.Group("`nOutput options`n    Output will be written to console by default`n"))
        op.Add(new OptParser.String("o", "", Venn.opts, "output", "file", "Write matching lines to file", OptParser.OPT_ARG))
        op.Add(new OptParser.Boolean(0, "keep-file", Venn.opts, "k", "Append to file instead of overwriting it", false))

        return _log.Exit(op)
    }

    run(args) {
        _log := new Logger("class." A_ThisFunc)

        if (_log.Logs(Logger.Input)) {
            _log.Input("args", args)
            if (_log.Logs(Logger.All)) {
                _log.All("args:`n" LoggingHelper.Dump(args))
            }
        }

        Venn.set_defaults()
        RC := 0

        try {
            op := Venn.cli()
            args := op.Parse(args)
            if (_log.Logs(Logger.Finest)) {
                _log.Finest("opts:`n" LoggingHelper.Dump(Venn.opts))
                _log.Finest("args:`n" LoggingHelper.Dump(args))
            }
            if (args.MinIndex() <> "") {
                throw Exception("error: Invalid argument(s): " Arrays.ToString(args, "; "))
            }
            if (Venn.opts.h) {
                Ansi.WriteLine(op.Usage())
            } else if (Venn.opts.version) {
                G_VERSION_INFO := { NAME: "AHK venn version v0.0.0", ARCH: "x" (A_PtrSize = 4 ? "86" : "64"), BUILD: A_YYYY A_MM A_DD A_Hour A_Min }
                #Include *i %A_ScriptDir%\.versioninfo
                Ansi.WriteLine(G_VERSION_INFO.NAME "/" G_VERSION_INFO.ARCH "-b" G_VERSION_INFO.BUILD)
            } else {
                if (!FileExist(Venn.opts.set_A)) {
                    throw Exception("error: Argument -A is an invalid file or missing")
                }
                if (!FileExist(Venn.opts.set_B)) {
                    throw Exception("error: Argument -B is an invalid file or missing")
                }
                ; if (Venn.opts.op.Trim() = "") { ; NOTE: This is handled by the opt parser
                    ; throw Exception("error: operation is not set")
                ; }
                Venn.opts.output := Venn.opts.output.Trim()
                if (Venn.opts.v) {
                    if (Venn.opts.i = true || Venn.opts.a = true) {
                        Ansi.Write("Ignoring case`n")
                    } else {
                        Ansi.Write("Case sensitive`n")
                    }
                    if (Venn.opts.l = true || Venn.opts.a = true) {
                        Ansi.Write("Ignoring leading spaces`n")
                    }
                    if (Venn.opts.t = true || Venn.opts.a = true) {
                        Ansi.Write("Ignoring trailing spaces`n")
                    }
                    if (Venn.opts.b) {
                        Ansi.Write("Ignoring blank lines`n")
                    }
                    if (Venn.opts.u) {
                        Ansi.Write("Printing no duplicates`n")
                    }
                    Ansi.Write("Set 'A' is " Venn.opts.set_A " with encoding " Venn.opts.enc_A "`n")
                    Ansi.Write("Set 'B' is " Venn.opts.set_B " with encoding " Venn.opts.enc_B "`n")
                    Ansi.Write("Performing operation " Venn.OP_NAME[Venn.opts.op] "`n")
                    if (Venn.opts.output.Trim() <> "") {
                        if (Venn.opts.k) {
                            Ansi.Write("Appending to file " Venn.opts.output "`n")
                        } else {
                            Ansi.Write("Overwrting file " Venn.opts.output "`n")
                        }
                    }
                }

                if (_log.Logs(Logger.Finest)) {
                    _log.Finest("Venn.opts:`n" LoggingHelper.Dump(Venn.opts))
                }

                RC := Venn.do_operation(Venn.opts.op, Venn.opts.set_A, Venn.opts.set_B)
            }
        } catch _ex {
            if (_log.Logs(Logger.SEVERE)) {
                _log.SEVERE("error: @" _ex.File "#" _ex.Line " : " _ex.Message)
            }
            Ansi.Write(_ex.Message "`n")
            Ansi.write(op.Usage() "`n")
        }

        return _log.Exit(RC)
    } 
}

/*
 * Function: op_cb
 *          Callback function for opt parser.
 *
 * Parameter:
 *          pValue - Abbreviated operation name
 *
 * Throws:
 *          An exception, if an invalid operation name is provided.
 *
 * Remarks:
 *          Operation names:
 *          is - 1 = A:( (*) ):B Intersection
 *          un - 2 = A:(*(*)*):B Union 
 *          sd - 3 = A:(*( )*):B Symetric Differnce 
 *          rc - 4 = A:(*( ) ):B Relative Complement 
 */
op_cb(pValue, no_opt = "") {
    _log := new Logger("app.venn." A_ThisFunc)

    if (_log.Logs(Logger.INPUT)) {
        _log.Input("pValue", pValue)
    }

    if (pValue = "is") {
        return _log.Exit(1)
    } else if (pValue = "un") {
        return _log.Exit(2)
    } else if (pValue = "sd") {
        return _log.Exit(3)
    } else if (pValue = "rc") {
        return _log.Exit(4)
    } else {
        throw Exception("Invalid operation: " pValue)
    }
}

#NoEnv                                              ; NOTEST-BEGIN
SetBatchLines -1

#Include <logging>
#Include <ansi>
#Include <optparser>
#Include <system>
#Include <string>

main:
    _main := new Logger("app.venn.main")
exitapp _main.Exit(Venn.run(System.vArgs))        ; NOTEST-END
; vim:tw=0:ts=4:sts=4:sw=4:et:ft=autohotkey:nobomb

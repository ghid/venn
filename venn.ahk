#NoEnv
SetBatchLines -1

#Include <logging>
#Include <console>
#Include <optparser>
#Include <system>
#Include <string>

op_cb(pValue, no_opt = "") {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("pValue", pValue)
		_log.Input("no_opt", no_opt)
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

main:
	_main := new Logger("app.venn.main")

	global G_h, G_a, G_i, G_l, G_t, G_u, G_op, G_b, G_v, G_k, G_output, G_output_file, G_enc_A, G_enc_B

	OP_NAME := ["'Intersection' A:( (*) ):B", "'Union' A:(*(*)*):B", "'Symmetric Difference' A:(*( )*):B", "'Relative Complement' A:(*( ) ):B"]

	RC := 0

	op := new OptParser("venn [options] --operation=< is | un | sd | rc > -A <file> -B <file>")
	op.Add(new OptParser.Group("General options"))
	op.Add(new OptParser.Boolean("h", "help", G_h, "This help", OptParser.OPT_HIDDEN))
	op.Add(new OptParser.Boolean("a", "ignore-all", G_a, "Ignore leading and trailing spaces`; ignore case",, false))
	op.Add(new OptParser.Boolean("i", "ignore-case", G_i, "Ignore case", OptParser.OPT_NEG, -1))
	op.Add(new OptParser.Boolean("l", "ignore-leading-spaces", G_l, "Ignore leading spaces", OptParser.OPT_NEG, -1))
	op.Add(new OptParser.Boolean("t", "ignore-trailing-spaces", G_t, "Ignore trailing spaces", OptParser.OPT_NEG, -1))
	op.Add(new OptParser.Boolean("b", "ignore-blank-lines", G_b, "Ignore blank line (default)", OptParser.OPT_NEG, true))
	op.Add(new OptParser.Boolean("u", "unique", G_u, "Only keep the first of multiple identical lines"))
	op.Add(new OptParser.Boolean("v", "verbose", G_v, "Verbose output"))
	op.Add(new OptParser.String(0, "enc-A", G_enc_A, "encoding", "Encoding of file A", OptParser.OPT_ARG,, "cp1252"))
	op.Add(new OptParser.String(0, "enc-B", G_enc_B, "encoding", "Encoding fo file B", OptParser.OPT_ARG,, "cp1252"))
	op.Add(new Optparser.Group("`nSets"))
	op.Add(new OptParser.String("A", "", _set_a, "file", "File name to use as set A", OptParser.OPT_ARG))
	op.Add(new OptParser.String("B", "", _set_b, "file", "File name to use as set B", OptParser.OPT_ARG))
	op.Add(new OptParser.Group("`nOperations"))
	op.Add(new OptParser.Callback(0, "operation", G_op, "op_cb", "operation"
		, ["Select an operation to perform (the '*' represents the result set):"
		, ". is: " OP_NAME[1]
		, ". un: " OP_NAME[2]
		, ". sd: " OP_NAME[3]
		, ". rc: " OP_NAME[4]]))
	op.Add(new OptParser.Group("`nOutput options`n    Output will be written to console by default`n"))
	op.Add(new OptParser.String("o", "", G_output, "file", "Write matching lines to file", OptParser.OPT_ARG))
	op.Add(new OptParser.Boolean(0, "keep-file", G_k, "Append to file instead of overwriting it", false))

	try {
		args := op.Parse(System.vArgs)
		if (_main.Logs(Logger.Finest)) {
			_main.Finest("G_h", G_h)
			_main.Finest("G_a", G_a)
			_main.Finest("G_i", G_i)
			_main.Finest("G_l", G_l)
			_main.Finest("G_t", G_t)
			_main.Finest("G_b", G_b)
			_main.Finest("G_u", G_u)
			_main.Finest("G_v", G_v)
			_main.Finest("_set_a", _set_a)
			_main.Finest("_set_b", _set_b)
			_main.Finest("G_op", G_op)
			_main.Finest("G_output", G_output)
			_main.Finest("G_k", G_k)
			_main.Finest("G_enc_A", G_enc_A)
			_main.Finest("G_enc_B", G_enc_B)
		}
		if (args.MinIndex() <> "")
			throw Exception("error: Invalid argument(s): " Arrays.ToString(args, "; "))
		if (G_h) {
			Console.Write(op.Usage() "`n")
		} else {
			if (!FileExist(_set_a))
				throw Exception("error: Argument -A is an invalid file or missing")
			if (!FileExist(_set_b))
				throw Exception("error: Argument -B is an invalid file or missing")
			if (G_op.Trim() = "")
				throw Exception("error: operation is not set")
			if (G_a) {
				if (G_i)
					G_i := true
				if (G_l)
					G_l := true
				if (G_t)
					G_t := true
			}
			G_output := G_output.Trim()
			if (G_v) {
				if (G_i = true)
					Console.Write("Ignoring case`n")
				else
					Console.Write("Case sensitive`n")
				if (G_l = true)
					Console.Write("Ignoring leading spaces`n")
				if (G_t = true)
					Console.Write("Ignoring trailing spaces`n")
				if (G_b)
					Console.Write("Ignoring blank lines`n")
				if (G_u)
					Console.Write("Printing no duplicates`n")
				Console.Write("Set 'A' is " _set_a " with encoding " G_enc_A "`n")
				Console.Write("Set 'B' is " _set_b " with encoding " G_enc_B "`n")
				Console.Write("Performing operation " OP_NAME[G_op] "`n")
				if (G_output.Trim() <> "") {
					if (G_k)
						Console.Write("Appending to file " G_output "`n")
					else
						Console.Write("Overwrting file " G_output "`n")
				}
			}

			RC := do_operation(G_op, _set_a, _set_b)
		}
	} catch _ex {
		if (_main.Logs(Logger.SEVERE))
			_main.SEVERE("error: @" _ex.File "#" _ex.Line " : " _ex.Message)
		Console.Write(_ex.Message "`n")
		Console.write(op.Usage() "`n")
	}

exitapp _main.Exit(RC)


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
	if (_log.Logs(Logger.ALL))
		_log.All("content:`n" LoggingHelper.HexDump(&content, 0, size * (A_IsUnicode ? 2 : 1)))
	file.Close()

	sort_option := (G_i = true ? "" : "C")
	if (_log.Logs(Logger.Finest)) {
		_log.Finest("G_i", G_i)
		_log.Finest("G_b", G_b)
		_log.Finest("sort_option = " sort_option)
	}
	Sort content, %sort_option%
	target := []
	loop Parse, content, % "`n", % Chr(26)
	{
		if (!G_b || A_LoopField.Trim() <> "")
			target.Insert(A_LoopField)
	}

	if (_log.Logs(Logger.Output)) {
		_log.Output("target", target)
		if (_log.Logs(Logger.ALL))
			_log.ALL("target:`n" LoggingHelper.Dump(target))
	}

	return _log.Exit()
}

do_operation(op, file_A, file_B) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("op", op)
		_log.Input("file_A", file_A)
		_log.Input("file_B", file_B)
	}
	
	load_file(A, file_A, G_enc_A)
	load_file(B, file_B, G_enc_B)

	i_A := A.MinIndex()
	i_B := B.MinIndex()
	if (_log.Logs(Logger.Finest)) {
		_log.Finest("i_A", i_A)
		_log.Finest("i_B", i_B)
		_log.Finest("A.MaxIndex()", A.MaxIndex())
		_log.Finest("B.MaxIndex()", B.MaxIndex())
	}

	VarSetCapacity(HIGH, 4, 0xFF)
	A.Insert(HIGH)
	B.Insert(HIGH)
	
	try {
		if (G_output <> "") {
			if (G_k) {
				G_output_file := FileOpen(G_output, "a")
			} else {
				G_output_file := FileOpen(G_output, "w")
			}
		}

		n := 0
		while (i_A < A.MaxIndex() || i_B < B.MaxIndex()) {
			while (i_A < A.MaxIndex() && compare(A[i_A], B[i_B]) < 0) {
				if (_log.Logs(Logger.Detail))
					_log.Detail("A[" i_A "]:" A[i_A] " < B[" i_B "]:" B[i_B])
				if (op = 2 || op = 3 || op = 4)
					output(A[i_A], n)
				i_A++
			}
			while (i_B < B.MaxIndex() && compare(B[i_B], A[i_A]) < 0) {
				if (_log.Logs(Logger.Detail))
					_log.Detail("B[" i_B "]:" B[i_B] " < A[" i_A "]:" A[i_A])
				if (op = 2 || op = 3)
					output(B[i_B], n)
				i_B++
			}
			while ((i_A < A.MaxIndex() || i_B < B.MaxIndex()) && compare(A[i_A], B[i_B]) = 0) {
				if (_log.Logs(Logger.Detail))
					_log.Detail("A[" i_A "]:" A[i_A] " = B[" i_B "]:" B[i_B])
				if (op = 1 || op = 2) {
					output(A[i_A], n)
					output(B[i_B], n)
				}
				i_A++
				if (op <> 4)
					i_B++
			}
		}
	} finally {
		if (G_output_file <> "")
			G_output_file.Close()
	}

	return _log.Exit(n)
}

output(pValue, ByRef count) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("pValue", pValue)
		_log.Input("count", count)
	}

	static last_value = ""
	if (_log.Logs(Logger.Finest)) {
		_log.Finest("last_value", last_value)
		_log.Finest("G_u", G_u)
		_log.Finest("G_i", G_i)
	}

	if (G_u && (G_i = true ? (pValue = last_value) : (pValue == last_value))) {
		if (_log.Logs(Logger.Detail)) {
			_log.Detail("Discard value from result: " pValue)
		}
		return
	}

	if (_log.Logs(Logger.Detail)) {
		_log.Detail("Add value to result: " pValue)
	}
	if (G_output <> "")
		G_output_file.WriteLine(pValue)
	else
		Console.Write(pValue "`n")
	last_value := pValue
	count++

	if (_log.Logs(Logger.Output))
		_log.Output("count", count)

	return _log.Exit()
}

compare(elem_A, elem_B) {
	_log := new Logger("app.venn." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("elem_A", elem_A)
		_log.Input("elem_B", elem_B)
	}
	
	if (_log.Logs(Logger.Finest)) {
		_log.Finest("G_l", G_l)
		_log.Finest("G_t", G_t)
	}
	if (G_l && G_t) {
		elem_A := elem_A.Trim(String.TRIM_ALL)
		elem_B := elem_B.Trim(String.TRIM_ALL)	
	} else if (G_l) {
		elem_A := elem_A.Trim(String.TRIM_LEFT)
		elem_B := elem_B.Trim(String.TRIM_LEFT)
	} else if (G_t) {
		elem_A := elem_A.Trim(String.TRIM_RIGHT)
		elem_B := elem_B.Trim(String.TRIM_RIGHT)
	}

	if (_log.Logs(Logger.Finest)) {
		_log.Finest("G_i", G_i)
	}

	return _log.Exit(elem_A.Compare(elem_B, (G_i = true ? false : true)))
}

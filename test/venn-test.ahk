#NoEnv
#Warn All, OutputDebug
SetBatchLines -1

#Include <logging>
#Include <testcase>

#Include <arrays>

#Include <console>
#Include <optparser>
#Include <system>
#Include <string>
#Include <ansi>

class VennTest extends TestCase {
	
	static FILE_A := A_Temp "\venn_A.txt"
		 , FILE_B := A_Temp "\venn_B.txt"
		 , FILE_RES := A_Temp "\venn_result.txt"
		 , FILE_CON := A_Temp "\venn_test.txt"

	@BeforeClass_Setup() {
		if (FileExist(VennTest.FILE_A))
			FileDelete, % VennTest.FILE_A
		if (FileExist(VennTest.FILE_B))
			FileDelete, % VennTest.FILE_B

		FileAppend,
			( LTrim
				i
				H
				f
				C
				B
				A
			), % VennTest.FILE_A

		FileAppend,
			( LTrim
				I
				G
				f
				e
				D
				C
				A
			), % VennTest.FILE_B
			
		if (!FileExist(VennTest.FILE_A))
			this.Fail("File not found: " VennTest.FILE_A)
		if (!FileExist(VennTest.FILE_B))
			this.Fail("File not found: " VennTest.FILE_B)
	}

	@AfterClass_Teardown() {
		if (FileExist(VennTest.FILE_A))
			FileDelete, % VennTest.FILE_A
		if (FileExist(VennTest.FILE_B))
			FileDelete, % VennTest.FILE_B
		if (FileExist(VennTest.FILE_RES))
			FileDelete, % VennTest.FILE_RES
	}

	@Before_Setup() {
        Venn.set_defaults()
		Venn.opts.output := VennTest.FILE_RES
		Venn.opts.output_file := FileOpen(Venn.opts.output, "w")
	}

	@After_Teardown() {
		Venn.opts.Close()
	}

	@BeforeRedirStdOut() {
		Ansi.StdOut := FileOpen(VennTest.FILE_CON, "w")
	}

	@AfterRedirStdOut() {
		Ansi.StdOut.Close()
		Ansi.StdOut := Ansi.__InitStdOut()
		FileDelete, % VennTest.FILE_CON
	}

	@Test_load_file_A() {
		Venn.load_file(A, "C:\Users\srp\AppData\Local\Temp\venn_A.txt")
		this.AssertEquals(A.MaxIndex(), 6)
		this.AssertTrue(Arrays.Equal(A, ["A", "B", "C", "H", "f", "i"]))
	}

	@Test_load_file_B() {
		Venn.load_file(B, "C:\Users\srp\AppData\Local\Temp\venn_B.txt")
		this.AssertEquals(B.MaxIndex(), 7)
		this.AssertTrue(Arrays.Equal(B, ["A", "C", "D", "G", "I", "e", "f"]))
	}

    @Test_Op_Callback() {
        this.AssertEquals(op_cb("is"), 1)
        this.AssertEquals(op_cb("un"), 2)
        this.AssertEquals(op_cb("sd"), 3)
        this.AssertEquals(op_cb("rc"), 4)
        this.AssertException("", "op_cb", "", "", "xx")
    }

	@Test_Union() {
		res := Venn.do_operation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 13)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "A", "B", "C", "C", "D", "G", "H", "I", "e", "f", "f", "i"]))
	}

	@Test_Union_Unique() {
		Venn.opts.u := true
		res := Venn.do_operation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 10)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "B", "C", "D", "G", "H", "I", "e", "f", "i"]))
	}

	@Test_Union_Unique_Ingnore_Case() {
		Venn.opts.u := true
		Venn.opts.i := true
		res := Venn.do_operation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 9)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "B", "C", "D", "e", "f", "G", "H", "i"]))
	}

	@Test_Intersection() {
		res := Venn.do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 6)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "A", "C", "C", "f", "f"]))
	}

	@Test_Intersection_With_Source() {
		Venn.opts.s := true
		res := Venn.do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 6)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["(A) A", "(B) A", "(A) C", "(B) C", "(A) f", "(B) f"]))
	}

	@Test_Intersection_Unique() {
		Venn.opts.u := true
		res := Venn.do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "C", "f"]))
	}

	@Test_Intersection_Unique_Ignore_Case() {
		Venn.opts.u := true
		Venn.opts.i := true
		res := Venn.do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 4)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "C", "f", "i"]))
	}

	@Test_Sym_Diff() {
		res := Venn.do_operation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 7)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "D", "G", "H", "I", "e", "i"]))
	}

	@Test_Sym_Diff_Unique() {
		Venn.opts.u := true
		res := Venn.do_operation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 7)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "D", "G", "H", "I", "e", "i"]))
	}

	@Test_Sym_Diff_Unique_Ignore_Case() {
		Venn.opts.u := true
		Venn.opts.i := true
		res := Venn.do_operation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 5)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "D", "e", "G", "H"]))
	}

	@Test_Rel_Comp() {
		res := Venn.do_operation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "H", "i"]))
		res := Venn.do_operation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.AssertEquals(res, 4)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["D", "G", "I", "e"]))
	}

	@Test_Rel_Comp_Unique() {
		Venn.opts.u := true
		res := Venn.do_operation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "H", "i"]))
		res := Venn.do_operation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.AssertEquals(res, 4)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["D", "G", "I", "e"]))
	}

	@Test_Rel_Comp_Unique_Ignore_Case() {
		Venn.opts.u := true
		Venn.opts.i := true
		res := Venn.do_operation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 2)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "H"]))
		res := Venn.do_operation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["D", "e", "G"]))
	}

	@Test_Portal_Abrechnung() {
		
		if (FileExist(A_Temp "\blacklist.txt"))
			FileDelete, % A_Temp "\blacklist.txt"
		if (FileExist(A_Temp "\users.txt"))
			FileDelete, % A_Temp "\users.txt"

		FileAppend,
			( LTrim
				thac
				scdd
			), % A_Temp "\blacklist.txt"

		FileAppend,
			( LTrim
				BChr
				scdd
				heap	
				ScdD
				ThaC
				zahl
			), % A_Temp "\users.txt"

		Venn.opts.u := true
		Venn.opts.a := true

		res := Venn.do_operation(4, A_Temp "\users.txt", A_Temp "\blacklist.txt")
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["BChr", "heap", "zahl"]))
	}

    @Test_Usage() {
        this.AssertEquals(Venn.run(["-h"]), 0)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON), TestCase.FileContent(A_ScriptDir "\figures\Usage.txt"))
    }

    @Test_VersionInfo() {
        this.AssertEquals(Venn.run(["--version"]), 0)
        Ansi.Flush()
        this.AssertTrue(RegExMatch(TestCase.FileContent(VennTest.FILE_CON), "AHK venn version v0\.0\.0/.*"))
    }

    @Test_Example1() {
        this.AssertEquals(Venn.run(["-s", "--operation", "un", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 13)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON), TestCase.FileContent(A_ScriptDir "\figures\UnionWithSource.txt"))
    }

    @Test_Example2() {
        if (FileExist(A_Temp "\venn-test.txt")) {
            FileDelete %A_Temp%\venn-test.txt
        }
        FileAppend TEST`n, %A_Temp%\venn-test.txt
        this.AssertEquals(Venn.run(["--keep-file", "-o", A_Temp "\venn-test.txt", "--operation", "un", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 13)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(A_Temp "\venn-test.txt"), "TEST`r`nA`nA`nB`nC`nC`nD`nG`nH`nI`ne`nf`nf`ni`n")
        if (FileExist(A_Temp "\venn-test.txt")) {
            FileDelete %A_Temp%\venn-test.txt
        }
    }

    @Test_Example3() {
        this.AssertEquals(Venn.run(["--operation", "un", "-lu", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 10)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON), TestCase.FileContent(A_ScriptDir "\figures\UniqueUnion.txt"))
    }

    @Test_Example4() {
        this.AssertEquals(Venn.run(["--operation", "un", "-tu", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 10)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON), TestCase.FileContent(A_ScriptDir "\figures\UniqueUnion.txt"))
    }

    @Test_Example5() {
        this.AssertEquals(Venn.run(["--operation", "un", "-auv", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 9)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON), TestCase.FileContent(A_ScriptDir "\figures\UniqueUnionIgnoreAll.txt"))
    }

    @Test_Example6() {
        if (FileExist(A_Temp "\venn-test.txt")) {
            FileDelete %A_Temp%\venn-test.txt
        }
        this.AssertEquals(Venn.run(["--operation", "un", "-v", "-o", A_Temp "\venn-test.txt", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 13)
        this.AssertEquals(Venn.run(["--operation", "un", "-vu", "-o", A_Temp "\venn-test.txt", "--keep-file", "-A", VennTest.FILE_A, "-B", VennTest.FILE_B]), 10)
        Ansi.Flush()
        this.AssertEquals(TestCase.FileContent(A_Temp "\venn-test.txt"), "A`nA`nB`nC`nC`nD`nG`nH`nI`ne`nf`nf`ni`nA`nB`nC`nD`nG`nH`nI`ne`nf`ni`n")
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON), TestCase.FileContent(A_ScriptDir "\figures\VerboseCreateAppendFile.txt"))
        if (FileExist(A_Temp "\venn-test.txt")) {
            FileDelete %A_Temp%\venn-test.txt
        }
    }

    @Test_ErrorHandling() {
        this.AssertEquals(Venn.run(["-A"]), 0)
        this.AssertEquals(Venn.run(["-A", VennTest.FILE_A, "-B"]), 0)
        this.AssertEquals(Venn.run(["--operation"]), 0)
        this.AssertEquals(Venn.run(["--operation", "un", "-A", VennTest.FILE_A, "-B", VennTest.File_B, "foo", "bar", "buzz"]), 0)
        this.AssertEquals(Venn.run(["--operation", "un", "-A", "foo.bar", "-B", VennTest.File_B]), 0)
        this.AssertEquals(Venn.run(["--operation", "un", "-A", VennTest.FILE_A, "-B", "foo.bar"]), 0)
        Ansi.Flush()
        usage := TestCase.FileContent(A_ScriptDir "\figures\Usage.txt")
        this.AssertEquals(TestCase.FileContent(VennTest.FILE_CON)
            , "Missing argument 'file'`n" usage
            . "Missing argument 'file'`n" usage
            . "Missing argument 'operation'`n" usage
            . "error: Invalid argument(s): foo; bar; buzz`n" usage
            . "error: Argument -A is an invalid file or missing`n" usage
            . "error: Argument -B is an invalid file or missing`n" usage)
    }
}

exitapp VennTest.RunTests()

load_file_into_array(file_name, enc, dump = false) {
	FileGetSize size, %file_name%
	file := FileOpen(file_name, "r`n", enc)
	content := file.Read(size)
	file.Close()

	target := []
	loop Parse, content, % "`n", % Chr(26)
	{
		target.Insert(A_LoopField)
		if (dump)
			OutputDebug %A_Index%: %A_LoopField%
	}

	target.Remove() ; Removes the last (blank) element

	return target
}

#Include %A_ScriptDir%\..\venn.ahk

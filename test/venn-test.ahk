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

class VennTest extends TestCase {
	
	static FILE_A := A_Temp "\venn_A.txt"
		 , FILE_B := A_Temp "\venn_B.txt"
		 , FILE_RES := A_Temp "\venn_result.txt"

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
		global G_output := VennTest.FILE_RES
		global G_output_file := FileOpen(G_output, "w")
		global G_i := false
		global G_l := false
		global G_t := false
		global G_u := false
		global G_b := true
		global G_v := false
		global G_k := false
		global G_enc_A := ""
		global G_enc_B := ""
	}

	@After_Teardown() {
		G_output_file.Close()
	}

	@Test_load_file_A() {
		load_file(A, "C:\Users\srp\AppData\Local\Temp\venn_A.txt")
		this.AssertEquals(A.MaxIndex(), 6)
		this.AssertTrue(Arrays.Equal(A, ["A", "B", "C", "H", "f", "i"]))
	}

	@Test_load_file_B() {
		load_file(B, "C:\Users\srp\AppData\Local\Temp\venn_B.txt")
		this.AssertEquals(B.MaxIndex(), 7)
		this.AssertTrue(Arrays.Equal(B, ["A", "C", "D", "G", "I", "e", "f"]))
	}

	@Test_Union() {
		res := do_operation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 13)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "A", "B", "C", "C", "D", "G", "H", "I", "e", "f", "f", "i"]))
	}

	@Test_Union_Unique() {
		global G_u := true
		res := do_operation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 10)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "B", "C", "D", "G", "H", "I", "e", "f", "i"]))
	}

	@Test_Union_Unique_Ingnore_Case() {
		global G_u := true
		global G_i := true
		res := do_operation(2, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 9)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "B", "C", "D", "e", "f", "G", "H", "i"]))
	}

	@Test_Intersection() {
		res := do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 6)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "A", "C", "C", "f", "f"]))
	}

	@Test_Intersection_Unique() {
		global G_u := true
		res := do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "C", "f"]))
	}

	@Test_Intersection_Unique_Ignore_Case() {
		global G_u := true
		global G_i := true
		res := do_operation(1, VennTest.File_A, VennTest.FILE_B)
		this.AssertEquals(res, 4)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["A", "C", "f", "i"]))
	}

	@Test_Sym_Diff() {
		res := do_operation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 7)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "D", "G", "H", "I", "e", "i"]))
	}

	@Test_Sym_Diff_Unique() {
		global G_u := true
		res := do_operation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 7)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "D", "G", "H", "I", "e", "i"]))
	}

	@Test_Sym_Diff_Unique_Ignore_Case() {
		global G_u := true
		global G_i := true
		res := do_operation(3, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 5)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "D", "e", "G", "H"]))
	}

	@Test_Rel_Comp() {
		res := do_operation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "H", "i"]))
		res := do_operation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.AssertEquals(res, 4)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["D", "G", "I", "e"]))
	}

	@Test_Rel_Comp_Unique() {
		global G_u := true
		res := do_operation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "H", "i"]))
		res := do_operation(4, VennTest.FILE_B, VennTest.FILE_A)
		this.AssertEquals(res, 4)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["D", "G", "I", "e"]))
	}

	@Test_Rel_Comp_Unique_Ignore_Case() {
		global G_u := true
		global G_i := true
		res := do_operation(4, VennTest.FILE_A, VennTest.FILE_B)
		this.AssertEquals(res, 2)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["B", "H"]))
		res := do_operation(4, VennTest.FILE_B, VennTest.FILE_A)
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
				thac
				zahl
			), % A_Temp "\users.txt"

		global G_u := true
		global G_i := true

		res := do_operation(4, A_Temp "\users.txt", A_Temp "\blacklist.txt")
		this.AssertEquals(res, 3)
		this.AssertTrue(Arrays.Equal(load_file_into_array(VennTest.FILE_RES, "cp1252"), ["BChr", "heap", "zahl"]))
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

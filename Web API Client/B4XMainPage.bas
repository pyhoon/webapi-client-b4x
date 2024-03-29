﻿B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Web_API_Client.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private URL As String = "http://192.168.50.42:19800/v1/" ' Change to your Web API Server URL
	Private lblTitle As B4XView
	Private lblBack As B4XView
	Private clvRecord As CustomListView
	Private btnEdit As B4XView
	Private btnDelete As B4XView
	Private btnNew As B4XView
	Private lblName As B4XView
	Private lblCategory As B4XView
	Private lblCode As B4XView
	Private lblPrice As B4XView
	Private lblStatus As B4XView
	Private indLoading As B4XLoadingIndicator
	Private PrefDialog1 As PreferencesDialog
	Private PrefDialog2 As PreferencesDialog
	Private PrefDialog3 As PreferencesDialog
	Dim Viewing As String
	Dim CategoryId As Long
	Dim Category() As Category
	Type Category (Id As Long, Name As String)
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "Web API Client")
	#if B4J
	CallSubDelayed3(Me, "SetScrollPaneBackgroundColor", clvRecord, xui.Color_Transparent)
	#End If
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	If xui.IsB4A Then
		'back key in Android
		If PrefDialog1.BackKeyPressed Then Return False
		If PrefDialog2.BackKeyPressed Then Return False
		If PrefDialog3.BackKeyPressed Then Return False
	End If
	If Viewing = "Product" Then
		GetCategories
		Return False
	End If
	Return True
End Sub

'Don't miss the code in the Main module + manifest editor.
Private Sub IME_HeightChanged (NewHeight As Int, OldHeight As Int)
	PrefDialog1.KeyboardHeightChanged(NewHeight)
	PrefDialog2.KeyboardHeightChanged(NewHeight)
	PrefDialog3.KeyboardHeightChanged(NewHeight)
End Sub

#If B4J
Private Sub SetScrollPaneBackgroundColor(View As CustomListView, Color As Int)
	Dim SP As JavaObject = View.GetBase.GetView(0)
	Dim V As B4XView = SP
	V.Color = Color
	Dim V As B4XView = SP.RunMethod("lookup", Array(".viewport"))
	V.Color = Color
End Sub
#End If

Private Sub B4XPage_Appear
	GetCategories
End Sub

Private Sub B4XPage_Resize(Width As Int, Height As Int)
	If PrefDialog1.IsInitialized And PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Resize(Width, Height)
	If PrefDialog2.IsInitialized And PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Resize(Width, Height)
	If PrefDialog3.IsInitialized And PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Resize(Width, Height)
End Sub

#If B4J
Private Sub lblBack_MouseClicked (EventData As MouseEvent)
	GetCategories
End Sub
#Else
Private Sub lblBack_Click
	GetCategories
End Sub
#End If

Private Sub GetCategories
	Try
		Dim i As Long
		Dim sd As Object = SendData("GET", "categories", Null)
		Wait For (sd) Complete (Data As Map)
		If Data.Get("s") = "ok" Then
			Dim Items As List = Data.Get("r")
			Dim Category(Items.Size) As Category
			For Each Item As Map In Items
				Category(i).Id = Item.Get("id")
				Category(i).Name = Item.Get("category_name")
				i = i + 1
			Next
			clvRecord.Clear
			For i = 0 To Category.Length - 1
				clvRecord.Add(CreateCategoryItems(Category(i).Name, clvRecord.AsView.Width), Category(i).Id)
			Next
			Viewing = "Category"
			lblTitle.Text = "Category"
			lblBack.Visible = False
			CreateDialog1
			CreateDialog2
			CreateDialog3
		Else
			xui.MsgboxAsync(Data.Get("e"), "Error")
		End If
	Catch
		'Log(LastException)
		xui.MsgboxAsync(LastException.Message, "Error")
	End Try
End Sub

Private Sub GetProducts
	clvRecord.Clear
	Dim sd As Object = SendData("GET", $"find/product/cid/${CategoryId}"$, Null)
	Wait For (sd) Complete (Data As Map)
	If Data.Get("s") = "ok" Then
		If 204 = Data.Get("a") Then
			xui.MsgboxAsync(Data.Get("m"), "No Product")
		Else
			Dim Items As List = Data.Get("r")
			For Each Item As Map In Items
				clvRecord.Add(CreateProductItems(Item.Get("product_code"), GetCategoryName(Item.Get("category_id")), Item.Get("product_name"), NumberFormat2(Item.Get("product_price"), 1, 2, 2, True), clvRecord.AsView.Width), Item.Get("id"))
			Next
		End If
	End If
	Viewing = "Product"
	lblTitle.Text = GetCategoryName(CategoryId)
	lblBack.Visible = True
End Sub

Private Sub GetCategoryName (Id As Long) As String
	Dim i As Long
	For i = 0 To Category.Length - 1
		If Category(i).Id = Id Then
			Return Category(i).Name
		End If
	Next
	Return ""
End Sub

Private Sub GetCategoryId (Name As String) As Long
	Dim i As Long
	For i = 0 To Category.Length - 1
		If Category(i).Name = Name Then
			Return Category(i).Id
		End If
	Next
	Return 0
End Sub

Private Sub clvRecord_ItemClick (Index As Int, Value As Object)
	If Viewing = "Category" Then
		CategoryId = Value
		GetProducts
	End If
End Sub

Private Sub btnNew_Click
	If Category.Length = 0 Then Return
	If Viewing = "Product" Then
		Dim ProductMap As Map = CreateMap("Product Code": "", "Category": GetCategoryName(CategoryId), "Product Name": "", "Product Price": "", "id": 0)
		ShowDialog2("Add", ProductMap)
	Else
		Dim CategoryMap As Map = CreateMap("Category Name": "", "id": 0)
		ShowDialog1("Add", CategoryMap)
	End If
End Sub

Private Sub CreateCategoryItems (Name As String, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 90dip)
	p.LoadLayout("CategoryItem")
	lblName.Text = Name
	Return p
End Sub

Private Sub CreateProductItems (ProductCode As String, CategoryName As String, ProductName As String, ProductPrice As String, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	p.LoadLayout("ProductItem")
	lblCode.Text = ProductCode
	lblCategory.Text = CategoryName
	lblName.Text = ProductName
	lblPrice.Text = ProductPrice
	Return p
End Sub

Private Sub CreateDialog1
	PrefDialog1.Initialize(Root, "Category", 300dip, 70dip)
	PrefDialog1.Dialog.OverlayColor = xui.Color_ARGB(128, 0, 10, 40)
	PrefDialog1.Dialog.TitleBarHeight = 50dip
	PrefDialog1.LoadFromJson(File.ReadString(File.DirAssets, "template_category.json"))
End Sub

Private Sub CreateDialog2
	Dim categories As List
	categories.Initialize
	For i = 0 To Category.Length - 1
		categories.Add(Category(i).Name)
	Next
	PrefDialog2.Initialize(Root, "Product", 300dip, 250dip)
	PrefDialog2.Dialog.OverlayColor = xui.Color_ARGB(128, 0, 10, 40)
	PrefDialog2.Dialog.TitleBarHeight = 50dip
	PrefDialog2.LoadFromJson(File.ReadString(File.DirAssets, "template_product.json"))
	PrefDialog2.SetOptions("Category", categories)
	PrefDialog2.SetEventsListener(Me, "PrefDialog2") '<-- must add to handle events.
End Sub

Private Sub CreateDialog3
	PrefDialog3.Initialize(Root, "Delete", 300dip, 70dip)
	PrefDialog3.Theme = PrefDialog3.THEME_LIGHT
	PrefDialog3.Dialog.OverlayColor = xui.Color_ARGB(128, 0, 10, 40)
	PrefDialog3.Dialog.TitleBarHeight = 50dip
	PrefDialog3.Dialog.TitleBarColor = xui.Color_RGB(220, 20, 60)
	PrefDialog3.AddSeparator("default")
End Sub

Private Sub ShowDialog1 (Action As String, Item As Map)
	If Action = "Add" Then
		PrefDialog1.Dialog.TitleBarColor = xui.Color_RGB(50, 205, 50)
	Else
		PrefDialog1.Dialog.TitleBarColor = xui.Color_RGB(65, 105, 225)
	End If
	PrefDialog1.Title = Action & " Category"
	Dim sf As Object = PrefDialog1.ShowDialog(Item, "OK", "CANCEL")
	#if B4A or B4i
	PrefDialog1.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	'Dim sp As ScrollPane = PrefDialog1.CustomListView1.sv
	'sp.SetVScrollVisibility("NEVER")
	Sleep(0)
	PrefDialog1.CustomListView1.sv.Height = PrefDialog1.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	' Fix Linux UI (Long Text Button)
	Dim btnCancel As B4XView = PrefDialog1.Dialog.GetButton(xui.DialogResponse_Cancel)
	btnCancel.Width = btnCancel.Width + 20dip
	btnCancel.Left = btnCancel.Left - 20dip
	btnCancel.TextColor = xui.Color_Red
	Dim btnOk As B4XView = PrefDialog1.Dialog.GetButton(xui.DialogResponse_Positive)
	btnOk.Left = btnOk.Left - 20dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If 0 = Item.Get("id") Then ' New row
			Dim CategoryMap As Map = CreateMap("name": Item.Get("Category Name"))
			Dim sd As Object = SendData("POST", "categories", CategoryMap)
			Wait For (sd) Complete (Data As Map)
			If Data.Get("s") = "ok" Then
				'Log(Data.Get("a")) ' 201 Created
				Dim l As List = Data.Get("r")
				Dim m As Map = l.Get(0)
				xui.MsgboxAsync("New category created!", $"ID: ${m.Get("id")}"$)
			Else
				xui.MsgboxAsync(Data.Get("e"), "Error")
				Return
			End If
		Else
			Dim CategoryMap As Map = CreateMap("name": Item.Get("Category Name"))
			Dim sd As Object = SendData("PUT", $"categories/${Item.Get("id")}"$, CategoryMap)
			Wait For (sd) Complete (Data As Map)
			If Data.Get("s") = "ok" Then
				xui.MsgboxAsync("Category updated!", "Edit")
			Else
				xui.MsgboxAsync(Data.Get("e"), "Error")
			End If
		End If
		GetCategories
	Else
		Return
	End If
End Sub

Private Sub ShowDialog2 (Action As String, Item As Map)
	If Action = "Add" Then
		PrefDialog2.Dialog.TitleBarColor = xui.Color_RGB(50, 205, 50)
	Else
		PrefDialog2.Dialog.TitleBarColor = xui.Color_RGB(65, 105, 225)
	End If
	PrefDialog2.Title = Action & " Product"
	Dim sf As Object = PrefDialog2.ShowDialog(Item, "OK", "CANCEL")
	Sleep(0)
	PrefDialog2.CustomListView1.sv.Height = PrefDialog2.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If 0 = Item.Get("id") Then ' New row
			CategoryId = GetCategoryId(Item.Get("Category"))
			Dim ProductMap As Map = CreateMap("cat_id": CategoryId, "code": Item.Get("Product Code"), "name": Item.Get("Product Name"), "price": Item.Get("Product Price"))
			Dim sd As Object = SendData("POST", $"products"$, ProductMap)
			Wait For (sd) Complete (Data As Map)
			If Data.Get("s") = "ok" Then
				'Log(Data.Get("a")) ' 201 Created
				Dim l As List = Data.Get("r")
				Dim m As Map = l.Get(0)
				xui.MsgboxAsync("New product created!", $"ID: ${m.Get("id")}"$)
			Else
				xui.MsgboxAsync(Data.Get("e"), "Error")
			End If
		Else
			Dim NewCategoryId As Long = GetCategoryId(Item.Get("Category"))
			Dim ProductMap As Map = CreateMap("cat_id": NewCategoryId, "code": Item.Get("Product Code"), "name": Item.Get("Product Name"), "price": Item.Get("Product Price"))
			Dim sd As Object = SendData("PUT", $"products/${Item.Get("id")}"$, ProductMap)
			Wait For (sd) Complete (Data As Map)
			If Data.Get("s") = "ok" Then
				xui.MsgboxAsync("Product updated!", "Edit")
				CategoryId = NewCategoryId
			Else
				xui.MsgboxAsync(Data.Get("e"), "Error")
			End If
		End If
		GetProducts
	Else
		Return
	End If
End Sub

Private Sub PrefDialog2_BeforeDialogDisplayed (Template As Object)
	Try
		' Fix Linux UI (Long Text Button)
		Dim btnCancel As B4XView = PrefDialog2.Dialog.GetButton(xui.DialogResponse_Cancel)
		btnCancel.Width = btnCancel.Width + 20dip
		btnCancel.Left = btnCancel.Left - 20dip
		btnCancel.TextColor = xui.Color_Red
		Dim btnOk As B4XView = PrefDialog2.Dialog.GetButton(xui.DialogResponse_Positive)
		If btnOk.IsInitialized Then
			btnOk.Width = btnOk.Width + 20dip
			btnOk.Left = btnCancel.Left - btnOk.Width
		End If
	Catch
		Log(LastException)
	End Try
End Sub

Private Sub ShowDialog3 (Item As Map, Id As Long)
	PrefDialog3.Title = "Delete " & Viewing
	Dim sf As Object = PrefDialog3.ShowDialog(Item, "OK", "CANCEL")
	#if B4A or B4i
	PrefDialog3.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	' Fix Linux UI (Long Text Button)
	'Dim sp As ScrollPane = PrefDialog3.CustomListView1.sv
	'sp.SetVScrollVisibility("NEVER")
	Sleep(0)
	PrefDialog3.CustomListView1.sv.Height = PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	Dim btnCancel As B4XView = PrefDialog3.Dialog.GetButton(xui.DialogResponse_Cancel)
	btnCancel.Width = btnCancel.Width + 20dip
	btnCancel.Left = btnCancel.Left - 20dip
	btnCancel.TextColor = xui.Color_Red
	Dim btnOk As B4XView = PrefDialog3.Dialog.GetButton(xui.DialogResponse_Positive)
	btnOk.Left = btnOk.Left - 20dip
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Text = Item.Get("Item")
	#If B4i
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 16 ' Text too small in ios
	#Else
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 15 ' 14
	#End If
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Color = xui.Color_Transparent
	PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Color = xui.Color_Transparent
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If Viewing = "Product" Then
			Dim sd As Object = SendData("DELETE", $"products/${Id}"$, Null)
		Else
			Dim sd As Object = SendData("DELETE", $"categories/${CategoryId}"$, Null)
		End If
		Wait For (sd) Complete (Data As Map)
		If Data.Get("s") = "ok" Then
			xui.MsgboxAsync(Viewing & " deleted!", "Delete")
		Else
			xui.MsgboxAsync(Data.Get("e"), "Error")
		End If
	Else
		Return
	End If
	If Viewing = "Product" Then
		GetProducts
	Else
		GetCategories
	End If
End Sub

Private Sub btnEdit_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim ProductId As Long = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		#if b4i
		Dim v2 As B4XView = pnl.GetView(1).GetView(0) ' using panel
		#else
		Dim v2 As B4XView = pnl.GetView(1)
		#End If
		Dim v3 As B4XView = pnl.GetView(2)
		Dim v4 As B4XView = pnl.GetView(3)
		Dim ProductMap As Map = CreateMap("Product Code": v1.Text, "Category": v2.Text, "Product Name": v3.Text, "Product Price": v4.Text.Replace(",", ""), "id": ProductId)
		ShowDialog2("Edit", ProductMap)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		Dim CategoryMap As Map = CreateMap("Category Name": v1.Text, "id": CategoryId)
		ShowDialog1("Edit", CategoryMap)
	End If
End Sub

Private Sub btnDelete_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim Id As Long = clvRecord.GetValue(Index)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	Dim pnl As B4XView = lst.GetView(0)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim v1 As B4XView = pnl.GetView(2)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim v1 As B4XView = pnl.GetView(0)
	End If
	Dim M1 As Map
	M1.Initialize
	M1.Put("Item", v1.Text)
	ShowDialog3(M1, Id)
End Sub

Sub SendData (Method As String, EndPoint As String, Payload As Map) As ResumableSub
	Dim j As HttpJob
	Dim Data As Map
	Try
		Dim Link As String = $"${URL}${EndPoint}"$
		'Log("Link:" & Link)
		indLoading.Show
		j.Initialize("", Me)
		Select Method.ToUpperCase
			Case "POST"
				j.PostString(Link, Payload.As(JSON).ToString)
			Case "PUT"
				j.PutString(Link, Payload.As(JSON).ToString)
			Case "DELETE"
				j.Delete(Link)
			Case Else ' GET
				j.Download(Link)
		End Select
		Wait For (j) JobDone(j As HttpJob)
		If j.Success Then
			Data = j.GetString.As(JSON).ToMap 'ignore
			Data.Put("a", j.Response.StatusCode)
			#if B4J
			lblStatus.Text = "Connected to " & URL
			#Else
			lblStatus.Text = "Connected to " & CRLF & URL
			#End If
			lblStatus.TextColor = xui.Color_White
		Else
			If j.ErrorMessage.Contains($""s": "error""$) Then
				Data = j.ErrorMessage.As(JSON).ToMap 'ignore
				Data.Put("a", j.Response.StatusCode)
			Else
				Data = CreateMap("s": "error", "e": j.ErrorMessage, "m": "")
				Data.Put("a", j.Response.StatusCode)
				#if B4J
				lblStatus.Text = "Connection to " & URL & " failed"
				#Else
				lblStatus.Text = "Connection failed:" & CRLF & URL
				#End If
				lblStatus.TextColor = xui.Color_Red
			End If
		End If
	Catch
		Log(LastException.Message)
		Data = CreateMap("s": "error", "e": LastException.Message, "m": "")
		Data.Put("a", 0)
		lblStatus.Text = "Error: " & LastException.Message
		lblStatus.TextColor = xui.Color_Red
	End Try
	j.Release
	indLoading.Hide
	Return Data
End Sub

;-------------------------------------------------------------------------------
function WCSquareGroup::Init, LINE_COLOR=lineColor, FILL_COLOR=fillColor, $
  LINE_THICK=lineThick, IS_BACKGROUND=isBackground
  compile_opt idl2

  self.vertX = List()
  self.vertY = List()
  self.connectivity = List()
  
  if (N_Elements(lineColor) ne 0) then begin
    self.lineColor = lineColor
  endif
  if (N_Elements(fillColor) ne 0) then begin
    self.fillColor = fillColor
  endif 
  if (N_Elements(lineThick) ne 0) then begin
    self.lineThick = lineThick
  endif else begin
    self.lineThick = 0.25 
  endelse
  if (N_Elements(isBackground) ne 0) then begin
    self.isBackground = isBackground
  endif
  
  return, 1
end

;-------------------------------------------------------------------------------
pro WCSquareGroup::Cleanup
  compile_opt idl2

  if (Obj_Valid(self.vertX)) then begin
    Obj_Destroy, self.vertX
  endif
  if (Obj_Valid(self.vertY)) then begin
    Obj_Destroy, self.vertY
  endif
  if (Obj_Valid(self.connectivity)) then begin
    Obj_Destroy, self.connectivity
  endif
end

;-------------------------------------------------------------------------------
pro WCSquareGroup::GetProperty, ISBACKGROUND=isBackground, VERTX=VertX, $
  VERTY=VertY, CONNECTIVITY=connectivity, BACKGROUND_COLOR=backgroundColor
  compile_opt idl2

  if (Arg_Present(isBackground)) then begin
    isBackground = self.isBackground
  endif
  if (Arg_Present(VertX)) then begin
    VertX = self._ToArray(self.vertX)
  endif
  if (Arg_Present(vertY)) then begin
    vertY = self._ToArray(self.vertY)
  endif
  if (Arg_Present(connectivity)) then begin
    connectivity = self._ToArray(self.connectivity)
  endif
  if (Arg_Present(backgroundColor)) then begin
    backgroundColor = self.fillColor
  endif  
end

;-------------------------------------------------------------------------------
function WCSquareGroup::IsValid 
  compile_opt idl2
  
  if (self.vertX.Count() eq 0) then begin
    return, 0
  endif
  if (self.vertY.Count() eq 0) then begin
    return, 0
  endif
  if (self.connectivity.Count() eq 0) then begin
    return, 0
  endif
  return, 1
end

;-------------------------------------------------------------------------------
function WCSquareGroup::_ToArray, verts 
  compile_opt idl2
  
  if (verts.Count() eq 0) then begin
    return, !null
  endif

  arrVerts = Transpose(verts.ToArray())
  
  return, Reform(arrVerts, N_Elements(arrVerts))
end

;-------------------------------------------------------------------------------
pro WCSquareGroup::Draw
  compile_opt idl2

  if (self.IsValid()) then begin
    self.GetProperty, VERTX=vertX, VERTY=vertY, CONNECTIVITY=connectivity
    !null = Polygon(vertX, vertY, $
                    CONNECTIVITY=connectivity, $
                    /DEVICE, $
                    THICK=self.lineThick, $
                    COLOR=self.lineColor, $
                    FILL_COLOR=self.fillColor, $
                    LINESTYLE=(self.isBackground) ? 6 : 0)
  endif
end

;-------------------------------------------------------------------------------
pro WCSquareGroup::AddData, newVertX, newVertY, connectivity 
  compile_opt idl2

  self.vertX.Add, newVertX
  self.vertY.Add, newVertY
  self.connectivity.Add, [4, self.vertNumber, self.vertNumber+1, $
                          self.vertNumber+2, self.vertNumber+3]
  self.vertNumber += 4
end

;-------------------------------------------------------------------------------
pro WCSquareGroup__define
  compile_opt idl2, hidden

  void = {WCSquareGroup,            $
          vertX:  List(),           $
          vertY: List(),            $
          connectivity: List(),     $
          vertNumber: 0,            $
          lineColor: BytArr(3),     $
          fillColor: BytArr(3),     $
          lineThick: 0.0,           $
          isBackground: !false      $
         }
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-------------------------------------------------------------------------------
function WCImportantDate::Init, date, SIZE=size, LINE_COLOR=lineColor
  compile_opt idl2

  self.date = date
  self.weekCount = WCCalendarEngine.ComputesWeekNumber(date)

  if (N_Elements(lineColor) ne 0) then begin
    self.lineColor = lineColor
  endif else begin
    self.lineColor = [90,90,90]
  endelse

  if (N_Elements(size) ne 0) then begin
    self.size = size
  endif else begin
    self.size = 6
  endelse

  return, 1
end

;-------------------------------------------------------------------------------
pro WCImportantDate::Draw, name
  compile_opt idl2

  thick = 1.5
  !null = Ellipse(self.location[0], self.location[1], $
                  MAJOR=self.size, $
                  /DEVICE, $
                  THICK=thick*1.5, $
                  FILL_BACKGROUND=0, $ 
                  COLOR=self.lineColor)

  !null = PolyLine([self.location[0], self.annLocation[0]], $
                   [self.location[1], self.annLocation[1]], $                  
                   /DEVICE, $
                   LINESTYLE=0, $
                   THICK=thick, $
                   COLOR=self.lineColor)

  !null = Text(self.annLocation[0], self.annLocation[1], name, $ 
               ALIGNMENT=self.alignment, VERTICAL_ALIGNMENT=0.5, $
               /DEVICE, FONT_SIZE=10, FONT_NAME='Calibri', $
               COLOR=self.lineColor)
end

;-------------------------------------------------------------------------------
pro WCImportantDate::AddData, location, annLocation, alignment
  compile_opt idl2

  self.location = location
  self.annLocation = annLocation
  self.alignment = alignment
end

;-------------------------------------------------------------------------------
pro WCImportantDate__define
  compile_opt idl2, hidden

  void = {WCImportantDate,            $
          date: IntArr(3),            $ 
          weekCount: 0,               $
          location: [0.0, 0.0],       $
          annLocation: [0.0, 0.0],    $
          alignment: 0.0,             $
          size: 0,                    $
          lineColor: BytArr(3)        $          
         }
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-------------------------------------------------------------------------------
function WCCalendarEngine::Init, dateBorn, _REF_EXTRA=extra
  compile_opt idl2

  self.dateBorn = dateBorn  
  strToday = StrSplit(SysTime(0), /EXTRACT)
  self.today = [self.MonthStrToInt(strToday[1]), Fix(strToday[2]), Fix(strToday[-1])]
  self.todayWeek = self.ComputesWeekNumber(self.today) 
  self.squareGroups = OrderedHash()
  self.squareGroupDates = OrderedHash()
  self.importantDates = OrderedHash()

  return, 1
end

;-------------------------------------------------------------------------------
pro WCCalendarEngine::Cleanup
  compile_opt idl2

  if (Obj_Valid(self.importantDates)) then begin
    Obj_Destroy, self.importantDates
  endif
  if (Obj_Valid(self.squareGroupDates)) then begin
    Obj_Destroy, self.squareGroupDates
  endif
  if (Obj_Valid(self.squareGroups)) then begin
    Obj_Destroy, self.squareGroups
  endif

end

;-------------------------------------------------------------------------------
pro WCCalendarEngine::Draw 
  compile_opt idl2

  ; Background first
  foreach squareGroup, self.squareGroups do begin 
    squareGroup.GetProperty, ISBACKGROUND=isBackground
    if (isBackground) then begin
      squareGroup.Draw
    endif
  endforeach

  ; Then foreground
  foreach squareGroup, self.squareGroups do begin 
    squareGroup.GetProperty, ISBACKGROUND=isBackground
    if (~isBackground) then begin
      squareGroup.Draw
    endif
  endforeach

  ; Important dates
  foreach importantDate, self.importantDates, name do begin 
    importantDate.Draw, name
  endforeach
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::MonthStrToInt, str
  compile_opt idl2

  case StrUpCase(str) of 
    'JAN': return, 1
    'FEB': return, 2
    'MAR': return, 3
    'APR': return, 4
    'MAY': return, 5
    'JUN': return, 6
    'JUL': return, 7
    'AUG': return, 8
    'SEP': return, 9
    'OCT': return, 10
    'NOV': return, 11
    'DEC': return, 12
  endcase
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::IsYearCountCurrent, yearCount
  compile_opt idl2, static

  return, (yearCount+self.dateBorn[2] eq self.today[2])
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::GetImportantDate, YEAR=year, WEEK_COUNT=weekCount
  compile_opt idl2, static

  foreach importantDate,self.importantDates do begin
    if ((importantDate.date[2] eq year) && $
        (importantDate.weekCount eq weekCount)) then begin
      return, importantDate
    endif 
  endforeach
    
  return, !null
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::GetBackgroundGroupInfo
  compile_opt idl2, static

  if (self.squareGroupDates.Count() eq 0) then begin
    return, !null
  endif

  h = OrderedHash()
  foreach group, self.squareGroups, name do begin
    group.GetProperty, ISBACKGROUND=isBackground
    if (isBackground) then begin
      group.GetProperty, BACKGROUND_COLOR=bgColor
      h[name] = bgColor
    endif
  endforeach

  return, h

end

;-------------------------------------------------------------------------------
function WCCalendarEngine::GetForeground, YEAR_COUNT=yearCount, WEEK_COUNT=weekCount
  compile_opt idl2, static

  todayYearCount = self.today[2]-self.dateBorn[2]
  if ((yearCount lt todayYearCount) || $
           ((yearCount eq todayYearCount) && (weekCount le self.todayWeek))) then begin
    return, self.squareGroups['past']
  endif else begin
    return, self.squareGroups['future']
  endelse
  return, !null
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::GetBackground, DATE=date
  compile_opt idl2, static

  if (self.squareGroupDates.Count() eq 0) then begin
    return, !null
  endif

  dateNames = self.squareGroupDates.Keys()
  squareGroup = self.squareGroups[dateNames[0]]
  foreach dateName, dateNames do begin
    SGDate = self.squareGroupDates[dateName] 
    if (IMSL_DateToDays(date[1], date[0], date[2]) ge $
        IMSL_DateToDays(SGDate[1], SGDate[0], SGDate[2])) then begin 
      squareGroup = self.squareGroups[dateName]
    endif    
  endforeach
  
  return, squareGroup
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::ComputeSquareVertices, x, y, size
  compile_opt idl2

  halfSize = size/2.0  
  return, [[x-halfSize, x+halfSize, x+halfSize, x-halfSize], $
           [y-halfSize, y-halfSize, y+halfSize, y+halfSize]]
end

;-------------------------------------------------------------------------------
function WCCalendarEngine::ComputesWeekNumber, date
  compile_opt idl2, static

  year = 2015  ; Make sure we don't pick an odd year.
  nDays = IMSL_DateToDays(date[1], date[0], year) - $
          IMSL_DateToDays(1, 1, year)

  return, Fix(nDays/7.0)
end

;-------------------------------------------------------------------------------
pro WCCalendarEngine::AddSquareGroup, name, date, _REF_EXTRA=extra
  compile_opt idl2

  self.squareGroups[name] = Obj_New('WCSquareGroup', _EXTRA=extra)
  if (N_Elements(date) ne 0) then begin  
    self.squareGroupDates[name] = date
  endif
end

;-------------------------------------------------------------------------------
pro WCCalendarEngine::AddToday, name, _REF_EXTRA=extra
  compile_opt idl2

  self.importantDates[name] = Obj_New('WCImportantDate', self.today, _EXTRA=extra)
end

;-------------------------------------------------------------------------------
pro WCCalendarEngine::AddImportantDate, name, date, _REF_EXTRA=extra
  compile_opt idl2

  self.importantDates[name] = Obj_New('WCImportantDate', date, _EXTRA=extra)
end

;-------------------------------------------------------------------------------
pro WCCalendarEngine__define
  compile_opt idl2, hidden

  void = {WCCalendarEngine,                $
          dateBorn: IntArr(3),             $
          today: IntArr(3),                $
          todayWeek: 0,                    $
          importantDates: OrderedHash(),   $
          squareGroupDates: OrderedHash(), $          
          squareGroups: OrderedHash()      $
         }
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro Your_Life_In_Weeks
  compile_opt idl2

  periods = OrderedHash()
  importantDates = Hash()
    
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Begin Calendar Variables
  ; Enter dates as month, day, year.
    
  personName = 'Peter'
  dateBorn = [1, 1, 1970]
  
  ; Expected years of life
  nYears = 90
  
  periods['Early years'] = Hash('start', [dateBorn[0], dateBorn[1], dateBorn[2]], $
                                'color', [101,166,206])
  periods['School'] = Hash('start', [dateBorn[0], dateBorn[1], dateBorn[2]+4], $
                           'color', [179,224,175])  
  periods['College'] = Hash('start', [dateBorn[0], dateBorn[1], dateBorn[2]+18], $
                            'color', [254,232,168])
  periods['Work'] = Hash('start', [9, 1, 1995], $
                         'color', [253,170,131])
  periods['Retirement'] = Hash('start', [dateBorn[0], dateBorn[1], dateBorn[2]+65], $
                               'color', [224,110,123])
  
  importantDates['Brother born'] = [10, 6, 1972] 
  importantDates['Sister born'] = [2, 1, 1974]
  importantDates['Moved to San Francisco'] = [4, 29, 1980]  
  importantDates['Father died'] = [12, 12, 1994]
  importantDates['Moved to New York'] = [6, 10, 1998]
  importantDates['Got married'] = [10, 19, 1999]
  importantDates['Daughter born'] = [1, 7, 2000]
  importantDates['Son born'] = [8, 21, 2003]
  
  ; End Calendar Variables
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
  bornWeek = WCCalendarEngine.ComputesWeekNumber(dateBorn)

  ; Configuration
  size = 6
  borderSquare = 4
  importantDateSize = 6
  borderPageHor = 200
  borderPageVer = 40
  nWeeks = 52
  
  ; Colors and styles
  squareLine = [1,1,1] * 0
  pastFill = [1,1,1] * 100
  transparent = [1,1,1] * 255
  futureFill = transparent
  squareThick = 0.25
  
  calendar = Obj_New('WCCalendarEngine', dateBorn)

  ; Add the first mandatory square groups  
  calendar.AddSquareGroup, 'past', LINE_COLOR=squareLine, FILL_COLOR=pastFill, $
                                   LINE_THICK=squareThick, IS_BACKGROUND=!false 
  calendar.AddSquareGroup, 'future', LINE_COLOR=squareLine, FILL_COLOR=futureFill, $
                                     LINE_THICK=squareThick, IS_BACKGROUND=!false
  
  ; Add all the background square groups
  foreach period, periods, event do begin
    calendar.AddSquareGroup, event, $
                             period['start'], $
                             FILL_COLOR=period['color'], $
                             IS_BACKGROUND=!true
  endforeach
  
  ; Add Important Dates 
  foreach importantDate, importantDates, event do begin 
    calendar.AddImportantDate, event, $
                               importantDate, $                               
                               SIZE=importantDateSize
  endforeach
  
  ; Add today
  calendar.AddToday, 'YOU ARE HERE', $
                     SIZE=importantDateSize
  
  totalWeeks = nWeeks*(nYears+1)
  width = nWeeks * (borderSquare+size) + borderPageHor*2
  height = nYears * (borderSquare+size) + borderPageVer*2
  
  minRightLabelPos = 1000000
  minLeftLabelPos = 1000000
  squareNumber = 0  
  for yearCount=0, nYears do begin
    year = dateBorn[2]+yearCount
    weekNumberThisYear = 0
    for weekCount=1, nWeeks do begin

      ; Skip initial weeks of the first year until born
      if ((yearCount eq 0) && $
          (bornWeek gt weekNumberThisYear)) then begin
        squareNumber++
        weekNumberThisYear++ 
        continue
      endif
        
      xPosition = borderPageHor + weekCount*(size+borderSquare)
      yPosition = borderPageVer + (nYears-yearCount)*(size+borderSquare)
 
      newVertices = calendar.ComputeSquareVertices(xPosition, yPosition, size)
      squareForeground = calendar.GetForeground(YEAR_COUNT=yearCount, $
                                                WEEK_COUNT=weekNumberThisYear)
      squareForeground.AddData, newVertices[*,0], newVertices[*,1]

      d0 = IMSL_DateToDays(1, 1, year)  
      IMSL_DaysToDate, d0+(weekCount-1)*7, d, m, y 
      squareBackground = calendar.GetBackground(DATE=[m, d, y])
      if (Obj_Valid(squareBackground)) then begin
        newVertices = calendar.ComputeSquareVertices(xPosition, yPosition, size+borderSquare)
        squareBackground.AddData, newVertices[*,0], newVertices[*,1]
      endif

      importantDate = calendar.GetImportantDate(YEAR=year, $
                                                WEEK_COUNT=weekNumberThisYear)
      if (Obj_Valid(importantDate)) then begin
        randYPos = yPosition + RandomN(seed, 1)*(size+borderSquare)*2 
        if (weekNumberThisYear ge nWeeks/2) then begin
          xLabelPos = borderPageHor + nWeeks*(size+borderSquare) + 50
          labelAlignment = 0.0
          ; Make sure the labels don't overlap
          if (randYPos ge minRightLabelPos-20) then begin
            randYPos = minRightLabelPos-20
          endif
          minRightLabelPos = randYPos
        endif else begin
          xLabelPos = borderPageHor - 20
          labelAlignment = 1.0
          ; Make sure the labels don't overlap
          if (randYPos ge minLeftLabelPos-20) then begin
            randYPos = minLeftLabelPos-20
          endif
          minLeftLabelPos = randYPos
        endelse
        
        importantDate.AddData, [xPosition, yPosition], $
                               [xLabelPos, randYPos], $
                               labelAlignment
      endif
              
      squareNumber++ 
      weekNumberThisYear++

    endfor
  endfor

  win = Window(DIMENSIONS=[width, height], WINDOW_TITLE="Weekly Life Calendar", LOCATION=[2000, 0])

  if (Obj_Valid(polyg)) then begin
    polyg.Refresh, /DISABLE
  endif

  calendar.Draw

  ; Titles
  !null = Text(width/2.0, $
               height-borderpageVer/2.0, $
               'Your Life In Weeks: ' + personName, $
               /DEVICE, FONT_SIZE=20, FONT_NAME='Calibri', $
               ALIGNMENT=0.5, VERTICAL_ALIGNMENT=0.0)

  ; Labels
  !null = Text(borderPageHor, $
               (nYears+1)*(size+borderSquare)+borderpageVer, $
               'Age', /DEVICE, FONT_SIZE=10, FONT_NAME='Calibri', $
               ALIGNMENT=1.0, VERTICAL_ALIGNMENT=0.5)
  !null = Text(borderPageHor + (nWeeks+1)*(size+borderSquare), $
               (nYears+1)*(size+borderSquare)+borderpageVer, $
               'Year', /DEVICE, FONT_SIZE=10, FONT_NAME='Calibri', $
               ALIGNMENT=0.0, VERTICAL_ALIGNMENT=0.5)

  for yearCount=0, nYears do begin 
    if (calendar.IsYearCountCurrent(yearCount)) then begin
      color = [255,255,255]
      fillColor = [0,0,0]
      fillBackground = 1
    endif else begin
      color = [0,0,0]
      fillColor = !null
      fillBackground = 0
    endelse
    !null = Text(borderPageHor, $
                 (nYears-yearCount)*(size+borderSquare)+borderpageVer, $
                 StrTrim(yearCount,2), /DEVICE, FONT_SIZE=10, FONT_NAME='Calibri', $
                 ALIGNMENT=1.0, VERTICAL_ALIGNMENT=0.5, $
                 COLOR=color, FILL_BACKGROUND=fillBackground, FILL_COLOR=fillColor)
    !null = Text(borderPageHor + (nWeeks+1)*(size+borderSquare), $
                 (nYears-yearCount)*(size+borderSquare)+borderpageVer, $
                 StrTrim(yearCount+dateBorn[2],2), /DEVICE, FONT_SIZE=10, FONT_NAME='Calibri', $
                 ALIGNMENT=0.0, VERTICAL_ALIGNMENT=0.5, $
                 COLOR=color, FILL_BACKGROUND=fillBackground, FILL_COLOR=fillColor)  
  endfor
  
  
  ; Legend
  backgroundGroupInfo = calendar.GetBackgroundGroupInfo()
  nLabels = N_Elements(backgroundGroupInfo)
  if (nLabels ne 0) then begin
    xPos = IndGen(nLabels+2) / Float(nLabels+1) * nWeeks*(size+borderSquare)  
    i = 1
    foreach bgColor, backgroundGroupInfo, name do begin
      text = Text(xPos[i++] + borderpageHor, $
                  borderpageVer-10, $
                  name, /DEVICE, FONT_SIZE=12, FONT_NAME='Calibri', $ 
                  ALIGNMENT=0.5, VERTICAL_ALIGNMENT=1.0, $
                  COLOR=[0,0,0], /FILL_BACKGROUND, FILL_COLOR=bgColor)
    endforeach
  endif

  if (Obj_Valid(polyg)) then begin
    polyg.Refresh, DISABLE=0
  endif

  ;win.Save, 'c:\tmp\wcal.pdf'
  ;win.Save, 'c:\tmp\wcal.png'
end
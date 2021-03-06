#' Perform comparisons between GSEA results
#'
#' @param pathinput  The pathway where excel files are
#' @param pathoutput The pathway for the excel file output
#' @param excelsUP The excels where functional pathways are upregulated (positive NES)
#' @param excelsDOWN The excels where functional pathways are downregulated (negative NES)
#' @param contrast The contrast used in functional analysis and it shows in excel files names
#' @param filename The name for the excel file output (without extension)
#'
#' @return
#' @export
#'
#' @examples
excel.comparison <- function(pathinput, pathoutput,excelsUP, excelsDOWN, contrast, filename){
  
  
  require(openxlsx)
  require(dplyr)
  
  list <- list()
  UP.list<-list()
  DOWN.list <- list()
  exup<-gsub("_vs_", ".vs." ,excelsUP )
  exdown<-gsub("_vs_", ".vs." ,excelsDOWN )
  for (i in 1:length(contrast)){
    files.up<-grep(contrast[i] , exup)
    if(length(files.up) != 0){
      for (z in 1:length(files.up)){
        UP <- read.table(file = paste(pathinput,excelsUP[files.up[z]], sep="/"), sep ="\t", header = T)
        UP.keep<- UP[,c(1,6,7,8)]
        UP.list[[z]] <- UP.keep
        }
      UP.f<-do.call(rbind,UP.list)
      colnames(UP.f) <- c("NAME", paste("NES" , contrast[i], sep="."),paste("NOM.p.val" , contrast[i], sep="."), paste("FDR.q.val" , contrast[i], sep="."))
    }
    files.down<-grep(contrast , exdown)
    if (length(files.down) != 0) {
      for (g in 1:length(files.down)) {
        DOWN <- read.table(file = paste(pathinput, excelsDOWN[files.down[g]], sep="/"), sep ="\t", header = T)
        DOWN.keep <- DOWN[,c(1,6,7,8)]
        DOWN.list[[g]]<- DOWN.keep
      }
      DOWN.f <- do.call(rbind,DOWN.list)
      colnames(DOWN.f) <- c("NAME", paste("NES" , contrast[i], sep="."),paste("NOM.p.val" , contrast[i], sep="."), paste("FDR.q.val" , contrast[i], sep="."))
    }
    if (length(files.down) != 0 & length(files.up) != 0){
    list[[i]] <- rbind(UP.f, DOWN.f)
    colnames(list[[i]]) <- gsub(".x", "" , colnames(list[[i]]))
    colnames(list[[i]]) <- gsub(".y", "" , colnames(list[[i]]))
  }else if (length(files.down) == 0 & length(files.up) != 0){
    list[[i]] <- UP.f
    colnames(list[[i]]) <- gsub(".x", "" , colnames(list[[i]]))
    colnames(list[[i]]) <- gsub(".y", "" , colnames(list[[i]]))
  }else if (length(files.down) != 0 & length(files.up) == 0){
    list[[i]] <- DOWN.f
    colnames(list[[i]]) <- gsub(".x", "" , colnames(list[[i]]))
    colnames(list[[i]]) <- gsub(".y", "" , colnames(list[[i]]))
  }
}
  if (length(contrast) == 2){
    total <- merge(list[[1]], list[[2]], by = "NAME")
    # filter data
    keep <- total[(total[,3] < 0.05 & total[,4] < 0.1) | (total[,6] < 0.05 & total[,7] < 0.1),]
    
    # CREATE EXCEL
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = "All Data" )
    writeData(wb, 1  , keep, colNames = TRUE)
    
    
    headerStyle1 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE, textRotation = 90)
    headerStyle2 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    headerStyle3 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle2, rows = 1, cols = 1:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle1, rows = 1, cols = 2:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle3, rows = 1, cols = 1,
             gridExpand = TRUE)
    
    bodyStyle1 <- createStyle(fontSize = 10,
                              wrapText = TRUE)
    
    addStyle(wb, sheet = 1, bodyStyle1, rows = 2:(length(rownames(keep))+2),
             cols = 1:length(colnames(keep)), gridExpand = TRUE)
    
    NumberStyle <- createStyle( fontSize = 10, numFmt = "0.0000")
    NumberStyle_adj.pval <- createStyle (fontSize = 10, numFmt = "SCIENTIFIC")
    
    FDRcols <- grep("FDR", colnames(keep))
    adjPvalCols <- grep("NOM", colnames(keep))
    
    addStyle(wb, sheet = 1, NumberStyle, rows = 2:(nrow(keep)+1),
             cols = FDRcols, gridExpand = TRUE)
    addStyle(wb, sheet = 1 , NumberStyle_adj.pval, rows = 2:(nrow(keep)+1), cols = adjPvalCols, gridExpand = TRUE)
    
    
    freezePane(wb, sheet = 1 , firstRow=T, firstCol = T)
    
    setColWidths(wb, sheet = 1, cols = 1, widths = 70)
    setColWidths(wb, sheet = 1, cols = 2:7, widths = 10)
    
    setRowHeights(wb,sheet = 1, rows = 1, heights = 160)
    
    # 1r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$C2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$D2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 2n CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$F2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$G2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # SAVE EXCEL
    
    saveWorkbook(wb, file.path(pathoutput,paste(filename, "xlsx", sep=".")),overwrite = TRUE)
    
  }else if(length(contrast) == 3){
    total1 <- merge(list[[1]], list[[2]], by = "NAME")
    total <- merge(total1, list[[3]], by = "NAME")
    # filter data
    keep <- total[(total[,3] < 0.05 & total[,4] < 0.1) | (total[,6] < 0.05 & total[,7] < 0.1) | (total[,9] < 0.05 & total[,10] < 0.1) ,]
    
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = "All Data" )
    writeData(wb, 1  , keep, colNames = TRUE)
    
    
    headerStyle1 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE, textRotation = 90)
    headerStyle2 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    headerStyle3 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle2, rows = 1, cols = 1:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle1, rows = 1, cols = 2:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle3, rows = 1, cols = 1,
             gridExpand = TRUE)
    
    bodyStyle1 <- createStyle(fontSize = 10,
                              wrapText = TRUE)
    
    addStyle(wb, sheet = 1, bodyStyle1, rows = 2:(length(rownames(keep))+2),
             cols = 1:length(colnames(keep)), gridExpand = TRUE)
    
    NumberStyle <- createStyle( fontSize = 10, numFmt = "0.0000")
    NumberStyle_adj.pval <- createStyle (fontSize = 10, numFmt = "SCIENTIFIC")
    
    FDRcols <- grep("FDR", colnames(keep))
    adjPvalCols <- grep("NOM", colnames(keep))
    
    addStyle(wb, sheet = 1, NumberStyle, rows = 2:(nrow(keep)+1),
             cols = FDRcols, gridExpand = TRUE)
    addStyle(wb, sheet = 1 , NumberStyle_adj.pval, rows = 2:(nrow(keep)+1), cols = adjPvalCols, gridExpand = TRUE)
    
    
    freezePane(wb, sheet = 1 , firstRow=T, firstCol = T)
    
    setColWidths(wb, sheet = 1, cols = 1, widths = 70)
    setColWidths(wb, sheet = 1, cols = 2:7, widths = 10)
    
    setRowHeights(wb,sheet = 1, rows = 1, heights = 160)
    
    # 1r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$C2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$D2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 2n CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$F2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$G2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 3r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = "$I2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = "$J2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    
    # SAVE EXCEL
    
    saveWorkbook(wb, file.path(pathoutput,paste(filename, "xlsx", sep=".")),overwrite = TRUE)
    
  }else if(length(contrast) == 4){
    
    total1 <- merge(list[[1]], list[[2]], by = "NAME")
    tota2 <- merge(total1, list[[3]], by = "NAME")
    total <- merge(total2, list[[4]], by = "NAME")
    # filter data
    keep <- total[(total[,3] < 0.05 & total[,4] < 0.1) | (total[,6] < 0.05 & total[,7] < 0.1) | (total[,9] < 0.05 & total[,10] < 0.1) | (total[,12] < 0.05 & total[,13] < 0.1) ,]
    
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = "All Data" )
    writeData(wb, 1  , total, colNames = TRUE)
    
    
    headerStyle1 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE, textRotation = 90)
    headerStyle2 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    headerStyle3 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle2, rows = 1, cols = 1:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle1, rows = 1, cols = 2:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle3, rows = 1, cols = 1,
             gridExpand = TRUE)
    
    bodyStyle1 <- createStyle(fontSize = 10,
                              wrapText = TRUE)
    
    addStyle(wb, sheet = 1, bodyStyle1, rows = 2:(length(rownames(keep))+2),
             cols = 1:length(colnames(keep)), gridExpand = TRUE)
    
    NumberStyle <- createStyle( fontSize = 10, numFmt = "0.0000")
    NumberStyle_adj.pval <- createStyle (fontSize = 10, numFmt = "SCIENTIFIC")
    
    FDRcols <- grep("FDR", colnames(keep))
    adjPvalCols <- grep("NOM", colnames(keep))
    
    addStyle(wb, sheet = 1, NumberStyle, rows = 2:(nrow(keep)+1),
             cols = FDRcols, gridExpand = TRUE)
    addStyle(wb, sheet = 1 , NumberStyle_adj.pval, rows = 2:(nrow(keep)+1), cols = adjPvalCols, gridExpand = TRUE)
    
    
    freezePane(wb, sheet = 1 , firstRow=T, firstCol = T)
    
    setColWidths(wb, sheet = 1, cols = 1, widths = 70)
    setColWidths(wb, sheet = 1, cols = 2:7, widths = 10)
    
    setRowHeights(wb,sheet = 1, rows = 1, heights = 160)
    
    # 1r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$C2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$D2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 2n CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$F2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$G2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 3r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = "$I2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = "$J2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 4r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = "$L2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = "$M2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    
    # SAVE EXCEL
    
    saveWorkbook(wb, file.path(pathoutput,paste(filename, "xlsx", sep=".")),overwrite = TRUE)
    
  }else if(length(contrast) == 5){
    
    total1 <- merge(list[[1]], list[[2]], by = "NAME")
    total2 <- merge(total1, list[[3]], by = "NAME")
    total3 <- merge(total2, list[[4]], by = "NAME")
    total <- merge(total3, list[[d]], by = "NAME")
    
    # filter data
    keep <- total[(total[,3] < 0.05 & total[,4] < 0.1) | (total[,6] < 0.05 & total[,7] < 0.1) | (total[,9] < 0.05 & total[,10] < 0.1) | (total[,12] < 0.05 & total[,13] < 0.1) | (total[,15] < 0.05 & total[,16] < 0.1) ,]
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = "All Data" )
    writeData(wb, 1  , total, colNames = TRUE)
    
    
    headerStyle1 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE, textRotation = 90)
    headerStyle2 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    headerStyle3 <- createStyle(fontSize = 12, halign = "center",textDecoration = "Bold",
                                wrapText = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle2, rows = 1, cols = 1:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle1, rows = 1, cols = 2:length(colnames(keep)),
             gridExpand = TRUE)
    
    addStyle(wb, sheet = 1, headerStyle3, rows = 1, cols = 1,
             gridExpand = TRUE)
    
    bodyStyle1 <- createStyle(fontSize = 10,
                              wrapText = TRUE)
    
    addStyle(wb, sheet = 1, bodyStyle1, rows = 2:(length(rownames(keep))+2),
             cols = 1:length(colnames(keep)), gridExpand = TRUE)
    
    NumberStyle <- createStyle( fontSize = 10, numFmt = "0.0000")
    NumberStyle_adj.pval <- createStyle (fontSize = 10, numFmt = "SCIENTIFIC")
    
    FDRcols <- grep("FDR", colnames(keep))
    adjPvalCols <- grep("NOM", colnames(keep))
    
    addStyle(wb, sheet = 1, NumberStyle, rows = 2:(nrow(keep)+1),
             cols = FDRcols, gridExpand = TRUE)
    addStyle(wb, sheet = 1 , NumberStyle_adj.pval, rows = 2:(nrow(keep)+1), cols = adjPvalCols, gridExpand = TRUE)
    
    
    freezePane(wb, sheet = 1 , firstRow=T, firstCol = T)
    
    setColWidths(wb, sheet = 1, cols = 1, widths = 70)
    setColWidths(wb, sheet = 1, cols = 2:7, widths = 10)
    
    setRowHeights(wb,sheet = 1, rows = 1, heights = 160)
    
    # 1r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$C2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 2, row = 1:dim(keep)[1]+1, rule = "$D2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 2n CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$F2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 5, row = 1:dim(keep)[1]+1, rule = "$G2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 3r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = "$I2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 8, row = 1:dim(keep)[1]+1, rule = "$J2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 4r CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = "$L2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 11, row = 1:dim(keep)[1]+1, rule = "$M2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    # 5 CONTRAST
    
    conditionalFormatting(wb, sheet = 1, cols = 14, row = 1:dim(keep)[1]+1, rule = '<0', style=createStyle(bgFill = c("#FF0000")))
    conditionalFormatting(wb, sheet = 1, cols = 14, row = 1:dim(keep)[1]+1, rule = '>=0', style=createStyle(bgFill = c("#90EE90")))
    conditionalFormatting(wb, sheet = 1, cols = 14, row = 1:dim(keep)[1]+1, rule = "$O2>0.05", style=createStyle(bgFill = c("#ffffff")))
    conditionalFormatting(wb, sheet = 1, cols = 14, row = 1:dim(keep)[1]+1, rule = "$P2>0.1", style=createStyle(bgFill = c("#ffffff")))
    
    
    # SAVE EXCEL
    
    saveWorkbook(wb, file.path(pathoutput,paste(filename, "xlsx", sep=".")),overwrite = TRUE)
  }
}



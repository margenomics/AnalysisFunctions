##' Run a universal enrichment for a list of contrasts with cluterProfiler function "enricher" 
##'
##' Function that performs a gene-set enrichment analysis using the function enricher
##' from clusterProfiler package. This function performs an hypergeometric test for each gene set.
##' 
##' @param data4Tyers data4tyers dataframe. Must contain a Geneid column and 
##' P.Value, adj.P.Val and logFC columns for each contrast (eg. "P.Value.LES_ACT.vs.LES_INACT")
##' @param contrast List with one vector of length 2 for each contrast.
##' @param gmt Data frame with gene sets. Can be obtained with function 
##' clusterProfiler::read.gmt. Must have a column "term" and a column "gene".
##' @param collection_name Vector with the name of the collection. It will be 
##' appended to the output directory/files name (eg. "c5.go.bp")
##' @param resultsDir Character vector with output results directory. Default is working directory.
##' @param specie Name of the specie. Accepts "human" and "mouse". If "mouse", a dataframe 
##' with homologues must be provided (see HOM_MouseHuman)
##' @param HOM_MouseHuman dataframe with HOM_MouseHumanSequence.txt. Must have the 
##' following columns: HomoloGene.ID (common ID for homologues), Common.Organism.Name, Symbol
##' @param minGSSize minimal size of each geneSet for analyzing (default 15)
##' @param maxGSSize maximal size of genes annotated for testing (Default 500)
##' @param p.value  pvalue cutoff (default 0.05)
##' @param p.adjust adjusted pvalue cutoff (default 0.05)
##' @param logFC logFC cutoff (default to 0)
##' @return Returns a list with enrichemnt results for each contrast. The list is saved as a RData object 
##' in the resultsDir directory, along with a folder for each contrast containing an 
##' excel file with enrichment results.
##' @author Julia Perera Bel <jperera@imim.es>
##' @export
##' @import clusterProfiler
##' @import openxlsx 
enrichment.data4tyers <-function (data4Tyers, contrast,gmt,collection_name = "", resultsDir = getwd(), 
                       specie = "human",HOM_MouseHuman = "",minGSSize = 15, maxGSSize = 500, p.value = 0.05, 
                        p.adjust = 0.05, logFC=0) {
  # If data4tyers and contrasts, will run per contrast and separate UP and DOWN
  require(clusterProfiler)
  require(openxlsx)
  headerStyle1 <- createStyle(halign = "center", valign = "center", 
                              textDecoration = "Bold", wrapText = TRUE)
  if (specie == "mouse") {
    Human.HOM <- HOM_MouseHuman[HOM_MouseHuman$Common.Organism.Name == 
                                  "human", ]
    Mouse.HOM <- HOM_MouseHuman[HOM_MouseHuman$Common.Organism.Name == 
                                  "mouse, laboratory", ]
    sum(data4Tyers$Geneid %in% Mouse.HOM$Symbol)
    Mouse.ID <- Mouse.HOM[Mouse.HOM$Symbol %in% data4Tyers$Geneid, 
    ]
    colnames(Mouse.ID)[2:ncol(Mouse.ID)] <- paste(colnames(Mouse.ID)[2:ncol(Mouse.ID)], 
                                                  "Mouse", sep = ".")
    colnames(Human.HOM)[2:ncol(Human.HOM)] <- paste(colnames(Human.HOM)[2:ncol(Human.HOM)], 
                                                    "Human", sep = ".")
    Hum.nd.Mouse <- merge(Mouse.ID, Human.HOM, all.x = T, 
                          all.y = F, sort = FALSE)
    dim(Hum.nd.Mouse)
    Hum.nd.Mouse <- Hum.nd.Mouse[!is.na(Hum.nd.Mouse$Symbol.Human), 
    ]
    dim(Hum.nd.Mouse)
    Hum.nd.Mouse$Geneid <- Hum.nd.Mouse$Symbol.Mouse
    dim(data4Tyers)
    data4Tyers.HOM <- merge(data4Tyers[, c("Geneid", grep("logFC",colnames(data4Tyers), value = T),
                                           grep("P.Value",colnames(data4Tyers), value = T), 
                                           grep("adj.P.Val",colnames(data4Tyers), value = T))], 
                            Hum.nd.Mouse[, c("Geneid", "Symbol.Human")])
    
    dim(data4Tyers.HOM)
    save(data4Tyers.HOM, file = file.path(resultsDir, "data4Tyers.HOM.RData"))
    data4Tyers = data4Tyers.HOM
    colnames(data4Tyers)[colnames(data4Tyers) == "Geneid"] = "Geneid.mouse"
    colnames(data4Tyers)[colnames(data4Tyers) == "Symbol.Human"] = "Geneid"
  }
  enrichment = list()
  dir = resultsDir
  for (i in 1:length(contrast)) {
    enrichment[[i]] = list()
    names(enrichment)[i]=paste(contrast[[i]][1],"vs",contrast[[i]][2],sep=".")
    
    resultsDir = file.path(dir, paste("Enrichment", collection_name, 
                                      contrast[[i]][1], "vs", contrast[[i]][2], sep = "."))
    dir.create(resultsDir, showWarnings = F)
    
    adjp=paste("adj.P.Val",contrast[[i]][1],"vs",contrast[[i]][2],sep=".")
    p=paste("P.Value",contrast[[i]][1],"vs",contrast[[i]][2],sep=".")
    logfc=paste("logFC",contrast[[i]][1],"vs",contrast[[i]][2],sep=".")
    
    #Select lists of genes
    genes_UP <- data4Tyers[data4Tyers[,p] < p.value & data4Tyers[,adjp] < p.adjust & data4Tyers[,logfc] > logFC,"Geneid" ]
    genes_DOWN <- data4Tyers[data4Tyers[,p] < p.value & data4Tyers[,adjp] < p.adjust & data4Tyers[,logfc] < (-logFC),"Geneid" ]
    
    
    geneList = list(genes_UP,genes_DOWN)
    names(geneList) = c(contrast[[i]][[1]],contrast[[i]][[2]])
    
    enrichment[[i]][[names(geneList)[1]]] <- clusterProfiler::enricher(geneList[[1]], TERM2GENE = gmt,
                                                                       minGSSize = minGSSize,
                                                                       maxGSSize = maxGSSize, pvalueCutoff = 1)
    enrichment[[i]][[names(geneList)[2]]] <- clusterProfiler::enricher(geneList[[2]], TERM2GENE = gmt, 
                                                         minGSSize = minGSSize, 
                                                         maxGSSize = maxGSSize, pvalueCutoff = 1)

    wb <- createWorkbook()
    for (j in 1:length(contrast[[i]])) {
      addWorksheet(wb, sheetName = paste("Enriched in", 
                                         contrast[[i]][j]))
      writeData(wb, j, enrichment[[i]][[names(geneList)[j]]]@result[ -c(2,9)])

      setColWidths(wb, sheet = j, cols = 1:7, widths = c(35, 
                                                         6, 10, 10, 10, 10, 25))
      addStyle(wb, sheet = j, headerStyle1, rows = 1, 
               cols = 1:7, gridExpand = TRUE)
      setRowHeights(wb, sheet = j, rows = 1, heights = 30)
    }
    saveWorkbook(wb, file.path(resultsDir, paste("Enrichment", 
                                                 collection_name, contrast[[i]][1], "vs", contrast[[i]][2], 
                                                 "xlsx", sep = ".")), overwrite = TRUE)
  }
  resultsDir = dir
  save(enrichment, file = file.path(resultsDir, paste0("Enrichment", collection_name, 
                                                 ".RData")))
  return(enrichment)
  
  
}

##' Run a universal enrichment for a list of gens with cluterProfiler function "enricher" 
##'
##' Function that performs a gene-set enrichment analysis using the function enricher
##' from clusterProfiler package. This function performs an hypergeometric test for 
##' each gene set given a vector of genes.
##' 
##' @param geneList list of vectors containing gene-lists. An enrichment will be 
##' performed for each position  of the list (ie. for each vector of genes).
##' @param gmt Data frame with gene sets. Can be obtained with function 
##' clusterProfiler::read.gmt. Must have a column "term" and a column "gene". 
##' The gene IDs must be in the same ofrmat as geneList (eg. SYMBOLS)
##' @param collection_name Vector with the name of the collection. It will be 
##' appended to the output directory/files name (eg. "c5.go.bp")
##' @param resultsDir Character vector with output results directory. Default is working directory.
##' @param specie Name of the specie. Accepts "human" and "mouse". If "mouse", a dataframe 
##' with homologues must be provided (see HOM_MouseHuman)
##' @param HOM_MouseHuman dataframe with HOM_MouseHumanSequence.txt. Must have the 
##' following columns: HomoloGene.ID (common ID for homologues), Common.Organism.Name, Symbol
##' @param minGSSize minimal size of each geneSet for analyzing (default 15)
##' @param maxGSSize maximal size of genes annotated for testing (Default 500)
##' @return Returns a list with enrichemnt results for each contrast. The list is saved as a RData object 
##' in the resultsDir directory, along with a folder for each contrast containing an 
##' excel file with enrichment results.
##' @author Julia Perera Bel <jperera@imim.es>
##' @export
##' @import clusterProfiler
##' @import openxlsx 
enrichment.geneList <-function (geneList,gmt,collection_name = "", resultsDir = getwd(), 
                                  specie = "human",HOM_MouseHuman = "",minGSSize = 15, maxGSSize = 500) {
  # If data4tyers and contrasts, will run per contrast and separate UP and DOWN
  # If genelist provided, will run for length(genelist)
  require(clusterProfiler)
  require(openxlsx)
  headerStyle1 <- createStyle(halign = "center", valign = "center", 
                              textDecoration = "Bold", wrapText = TRUE)
  if (specie == "mouse") {
    cat("Converting mouse symbols to human homologues...\n")
    Human.HOM <- HOM_MouseHuman[HOM_MouseHuman$Common.Organism.Name == 
                                  "human", ]
    Mouse.HOM <- HOM_MouseHuman[HOM_MouseHuman$Common.Organism.Name == 
                                  "mouse, laboratory", ]
    geneList.HOM <- geneList
    for (i in 1:length(geneList)){
      cat("List",i,":",names(geneList)[i],"\n")
      sum(geneList[[i]] %in% Mouse.HOM$Symbol)
      Mouse.ID <- Mouse.HOM[Mouse.HOM$Symbol %in% geneList[[i]], ]
      colnames(Mouse.ID)[2:ncol(Mouse.ID)] <- paste(colnames(Mouse.ID)[2:ncol(Mouse.ID)], 
                                                    "Mouse", sep = ".")
      colnames(Human.HOM)[2:ncol(Human.HOM)] <- paste(colnames(Human.HOM)[2:ncol(Human.HOM)], 
                                                      "Human", sep = ".")
      Hum.nd.Mouse <- merge(Mouse.ID, Human.HOM, all.x = T, 
                            all.y = F, sort = FALSE)
      dim(Hum.nd.Mouse)
      Hum.nd.Mouse <- Hum.nd.Mouse[!is.na(Hum.nd.Mouse$Symbol.Human),  ]
      dim(Hum.nd.Mouse)
      Hum.nd.Mouse$Geneid <- Hum.nd.Mouse$Symbol.Mouse
      length(geneList[[i]])
      geneList.HOM [[i]] <- Hum.nd.Mouse$Symbol.Human[match(geneList[[i]], Hum.nd.Mouse$Geneid)]
      geneList.HOM [[i]] <- unique(na.omit(geneList.HOM [[i]]))
      
      length(geneList.HOM [[i]])
      cat("\tFrom",length(unique(geneList[[i]])),"initial genes,",length(geneList.HOM [[i]]),"mapped to human homologues\n")
      
    }
    geneList=geneList.HOM
    
  }
  enrichment = list()
  dir = resultsDir
  for (i in 1:length(geneList)) {
    cat("Running enrichment",i,":",names(geneList)[i],"\n")
    
    resultsDir = file.path(dir, paste("Enrichment", collection_name, 
                                      names(geneList)[i], sep = "."))
    dir.create(resultsDir, showWarnings = F)
    
  
    enrichment[[i]] <- clusterProfiler::enricher(geneList[[i]], TERM2GENE = gmt,
                                                 minGSSize = minGSSize,
                                                 maxGSSize = maxGSSize, pvalueCutoff = 1)
    names(enrichment)[i] <- names(geneList)[i]
    wb <- createWorkbook()
    addWorksheet(wb, sheetName = paste0("Enrichment ", collection_name))
    writeData(wb, 1, enrichment[[i]]@result[ -c(2,9)])
    setColWidths(wb, sheet = 1, cols = 1:7, widths = c(35, 6, 10, 10, 10, 10, 25))
    addStyle(wb, sheet = 1, headerStyle1, rows = 1, 
             cols = 1:7, gridExpand = TRUE)
    setRowHeights(wb, sheet = 1, rows = 1, heights = 30)
    saveWorkbook(wb, file.path(resultsDir, paste("Enrichment", 
                                                 collection_name, names(geneList)[i], 
                                                 "xlsx", sep = ".")), overwrite = TRUE)
  }
  resultsDir = dir
  save(enrichment, file = file.path(resultsDir, paste0("Enrichment", collection_name, 
                                                       ".RData")))
  cat(i," enrichemnts done!\n")
  
  return(enrichment)
  
  
}

##' Create plots summarizing enrichment results
##'
##' Function that creates dotplots, gene-concept networks 
##' and enrichmentMAP from clusterProfiler and enrichplot packages. 
##' @param enrichment enrichment results obtained with enrichment.geneList or enrichment.data4tyers functions
##' @param collection_name Name of the collection to append to output files.
##' @param resultsDir Character vector with output results directory. Default is working directory.
##' @param plot_top maximum number of GSEA plots (default 50 to return all results)
##' @param p.adjust adjusted pvalue cutoff (default 0.05). Gene sets with p.adjust 
##' below this threshold will be included in all plots, unless maximum for visualization is reached.
##' @return This function creates a folder for each contrast and generates
##' dotplots, gene-concept networks and enrichmentMAP for length(enrichment).
##' @author Julia Perera Bel <jperera@imim.es>
##' @export
##' @import clusterProfiler
##' @import enrichplot 
##' @import gridExtra
##' @import png 
##' @import ggplot2
enrichment.plots <- function (enrichment,collection_name = "", resultsDir = getwd(), 
          plot_top = 50, p.adjust = 0.05) 
{
  require(clusterProfiler)
  require(enrichplot)
  require(gridExtra)
  require(png)
  require(ggplot2)
  dir = resultsDir
  for (i in 1:length(enrichment)) {
    cat("Plotting:", names(enrichment)[i], "\n")
    resultsDir = file.path(dir, paste("Enrichment", collection_name, 
                                      names(enrichment)[i], sep = "."))
    dir.create(resultsDir, showWarnings = F)
  
    # Subset to significant results (with input p.adjust)
    enrichment[[i]]@result=enrichment[[i]]@result[ enrichment[[i]]@result$p.adjust < p.adjust,]

    if(nrow(enrichment[[i]]@result)!=0){ # If there are significant results; do plots
      enrichment[[i]]@result$Description=strtrim(enrichment[[i]]@result$Description, 70) # maximum label length
      p = clusterProfiler::dotplot(enrichment[[i]], showCategory = plot_top, 
                                   font.size = 8, 
                                   title = paste0("Top", plot_top," ",collection_name, 
                                                  "\n enriched in ", names(enrichment)[i], 
                                                  "\n p.adjust<",p.adjust))
      
      ggsave(file.path(resultsDir, paste0("Enrichment.", 
                                          collection_name, ".Dotplot.", names(enrichment)[i], 
                                          ".png")), plot = p, width = 9, height = ifelse(nrow(enrichment[[i]]@result)>5,8,3))
      p = clusterProfiler::cnetplot(enrichment[[i]], 
                                        cex_label_gene = 0.5, cex_label_category = 0.7, 
                                        cex_category = 0.7, layout = "kk", showCategory = 10)
      ggsave(file.path(resultsDir, paste0("Enrichment.", 
                                          collection_name, ".GeneConceptNetworks.", 
                                          names(enrichment)[i], ".png")), plot = p, width = 9, height = 8)
      if (nrow(enrichment[[i]]@result) > 1) {
        pt = enrichplot::pairwise_termsim(enrichment[[i]], 
                                          method = "JC", semData = NULL, showCategory = 200)
	        
	p <- clusterProfiler::emapplot(pt, cex_label_category = 0.5, 
                                       showCategory = 30)
        ggsave(file.path(resultsDir, paste0("Enrichment.", 
                                            collection_name, ".EnrichmentMAP.", names(enrichment)[i], 
                                            ".png")), plot = p, width = 9, height = ifelse(nrow(enrichment[[i]]@result)>5,8,3))
      }
      else {
        png::writePNG(array(0, dim = c(1, 1, 4)), 
                      file.path(resultsDir, paste0("Enrichment.", collection_name, 
                                                   ".EnrichmentMAP.", names(enrichment)[i], ".png")))
      }
    }
    else {
      png::writePNG(array(0, dim = c(1, 1, 4)), file.path(resultsDir, 
                                                          paste0("Enrichment.", collection_name, ".Dotplot.", 
                                                                 names(enrichment)[i], ".png")))
      png::writePNG(array(0, dim = c(1, 1, 4)), file.path(resultsDir, 
                                                          paste0("Enrichment.", collection_name, ".GeneConceptNetworks.", 
                                                                 names(enrichment)[i], ".png")))
      png::writePNG(array(0, dim = c(1, 1, 4)), file.path(resultsDir, 
                                                          paste0("Enrichment.", collection_name, ".EnrichmentMAP.", 
                                                                 names(enrichment)[i], ".png")))
    }
  }
}

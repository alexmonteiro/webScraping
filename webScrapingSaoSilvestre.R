## install.packages('XML', dep = TRUE)
## install.packages('RCurl', dep = TRUE)
library(XML)
library(RCurl)

## Resultado Masculino da 93a Corrida de São de Silvestre
#urlResultado <- "https://www.yescom.com.br/codigo_comum/classificacao/codigo/p_classificacao03_v1.asp?evento_yescom_id=1803&tipo=3&tipo_do_evento_id=5670"
## Resultado Feminino da 93a Corrida de São de Silvestre
urlResultado <- "https://www.yescom.com.br/codigo_comum/classificacao/codigo/p_classificacao03_v1.asp?evento_yescom_id=1803&tipo=4&tipo_do_evento_id=5670"

## Parse do HTML
h <- htmlParse(RCurl::getURL(urlResultado), encoding = "utf-8")
## Resumo com os quantitativos de tag html da p[agina] 
# summary(h)

## xPath da quantidade de páginas | Ex.: Pag. 1 a 802
xpPaginas <- "//span[@class = 'FontVermelha']"
## Aplica  xpathSApply no HTML (h) co o Path xpPaginas e a função xmlValue para retorna o valor dentro da tag
nPaginas <- xpathSApply(h, path = xpPaginas, fun = xmlValue) # Usando xpathSApply().
## Nomeia o vetor de pagáginas
names(nPaginas) <- c("primeira","ultima")
## class(nPaginas)

## xPath do cabeçalho da tabela de resultados
## O resultado da competição é exibido em uma tabela html
## que possui 8 colunas (CLASSIFICAÇÃO, NUM, ATLETA, IDADE, FX.ET., EQUIPE, TEMPO, TEMPO LÍQUIDO)
## e contem o cabecalho destacado pela cor #EFEFEF no atributo @bgcolor, seguido da tag <td> e <b>.
xpCabecalho <- "//tr[@bgcolor = '#EFEFEF']//td//b"
cabecalho <- xpathSApply(h, path = xpCabecalho, fun = xmlValue) # Usando xpathSApply().
## summary(cabecalho)

## xPath do Atleta
## Segue a mesma estrutura do cabecalho
## porém com o atributo @bgcolor = #FFFFFF no <tr> 
## e @class = font1
xpAtleta <- "//tr[@bgcolor = '#FFFFFF']//td[@class = 'font1']"

## Data Frame que receberá os atletas
dfAtletas <- NULL
## Loop entre a primeira e última página
for(i in nPaginas['primeira']:nPaginas['ultima']){
  ## Concatena o numero da pagina na url
  ## A navegação adota pelo site é realizada pelo parâmetro &PaginaAtual= na URL
  url <- paste0(urlResultado,'&PaginaAtual=',i)
  htmlAtleta <- htmlParse(RCurl::getURL(url), encoding = "utf-8")
  
  ## xpathSApply() para pegar o conteudo do Atleta
  ## O resultado será um array com os valores em sequencia de todos atletas
  atleta <- xpathSApply(htmlAtleta, path = xpAtleta, fun = xmlValue)
  
  ## Converte o resultado em uma matriz e em seguida converte para data frame
  ## Para as paginas com 10 resultaods a matriz será (80/8) por 8, [10,8],
  ## para a última página se tiver apenas 9 resultado será (72/8) por 8, [9,8]
  ## e assim sucessivamente.
  df <- as.data.frame(matrix(atleta, length(atleta)/length(cabecalho), length(cabecalho), byrow = TRUE))
  
  ## Concatena o df dos atletas da página atual com o dfAtletas do resultado final
  dfAtletas <- rbind(dfAtletas, df)
  print(paste0('Página ',i,' copiada.'))
}

## Nomeia o resultado com o cabecalho
names(dfAtletas) <- cabecalho

nrow(dfAtletas)

write.csv(dfAtletas, file = "resultado.csv", row.names = FALSE)

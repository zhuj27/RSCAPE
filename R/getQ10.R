#     R-Code to calculate Q10-value based on SCAPE
#     Copyright (C) 2013  Fabian Gans, Miguel Mahecha
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

getQ10 <-function(
  ##title<< Estimate $Q_{10}$ value and time varying $R_b$ from temperature and efflux time series including uncertainty.
  ##description<< Function to determine the temperature sensitivity ($Q_{10}$ value) and time varying 
  ## basal efflux (R$_b(i)$) from a given temperature and efflux (usually respiration) time series 
  ## according the principle of "SCAle dependent Parameter Estimation, SCAPE" (Mahecha et al. 2010).  
  temperature, ##<< numeric vector: temperature time series
  respiration, ##<< numeric vector: respiration time series
  sf,   ##<< numeric: sampling rate, number of measurements (per day)
  Tref=15, ##<< numeric: reference temperature in Q10 equation
  gam=10, ##<< numeric: gamma value in Q10 equation
  fborder=30, ##<< numeric: boundary for dividing high- and low-frequency parts (in days)
  M=-1, ##<< numeric vector: size of SSA window (in days)
  nss=0, ##<< numeric vector: number of surrogate samples 
  method="Fourier", ##<< String: method to be applied for signal decomposition (choose from "Fourier","SSA","MA","EMD","Spline")
  weights=NULL, ##<< numeric vector: optional vector of weights to be used for linear regression, points can be set to 0 for bad data points
  lag=NULL, ##<< numeric vector: optional vector of time lags between respiration and temprature signal
  gapFilling=TRUE, ##<< Logical: Choose whether Gap-Filling should be applied
  doPlot=FALSE ##<< Logical: Choose whether Surrogates should be plotted
) 
##details<<
##Function to determine the temperature sensitivity ($Q_{10}$ value) and time varying basal efflux (R$_b$) from a given temperature and efflux (usually respiration) time series. 
##Conventionally, the following model is used in the literature:
##
##  Resp(i) = R_b Q_{10}^((T(i)-Tref)/(gamma),
##
##where $i$ is the time index. It has been shown, however, that this model is misleading when $R_b$ is varying over time which can be expected in many real world examples (e.g. Sampson et al. 2008).
##
##If $R_b$ varies slowly, i.e. with some low frequency then the "scale dependent parameter estimation, SCAPE" 
##allows us to identify this oscillatory pattern. As a consequence, the estimation of $Q_{10}$ can be substantially stabilized (Mahecha et al. 2010). The model becomes 
##
##Resp(i) = R_b(i)Q_{10}^((T(i)-Tref)/(gamma),
##
##where $R_b(i)$ is the time varying "basal respiration", i.e. the respiration expected at $Tref$. The convenience function getQ10 allows to extract the $Q_{10}$ value minimizing the confounding factor of the time varying $R_b$. Four different spectral methods can be used and compared. A surrogate technique (function by curtsey of Dr. Henning Rust, written in the context of Venema et al. 2006) is applied to propagate the uncertainty due to the decomposition.
##
##The user is strongly encouraged to use the function with caution, i.e. see critique by Graf et al. (2011).

##author<<
##Fabian Gans, Miguel D. Mahecha, MPI BGC Jena, Germany, fgans@bgc-jena.mpg.de mmahecha@bgc-jena.mpg.de
{
  gettau <- function(temperature) {
    return((temperature-Tref)/gam)
  }
  
  getSensPar <- function(S) return(exp(S))
  
  invGetSensPar <- function(X) return(log(X))
  environment(invGetSensPar)<-baseenv()
  
  output <- getSens(temperature=temperature,
                    respiration=respiration,
                    sf=sf,
                    gettau=gettau,
                    fborder=fborder,
                    M=M,
                    nss=nss,
                    method=method,
                    weights=weights,
                    lag=lag,
                    gapFilling=gapFilling,
                    doPlot=doPlot)
  
  output <- .transformOutput(output,getSensPar,"Q10")
  
  output$settings$invGetSensPar <- invGetSensPar
  return(output)
  ##value<< 
  ##A list with elements
  ##
  ##$SCAPE_Q10 : the estimated Q_{10} with the SCAPE principle and the method chosen.
  ##$Conv_Q10 : the conventional Q_{10} (assuming constant Rb)
  ##$DAT$SCAPE_R_pred : the SCAPE prediction of respiration 
  ##$DAT$SCAPE_Rb : the basal respiration based on the the SCAPE principle
  ##$DAT$Conv_R_pred : the conventional prediction of respiration 
  ##$DAT$Conv_Rb : the conventional (constant) basal respiration
  
  return(output)
}

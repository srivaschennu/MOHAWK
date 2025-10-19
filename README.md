# Introduction

MOHAWK is a software prototype that brings together state of the art computational analysis of brain activity to benefit patients with severe brain injury at their bedside. This prototype includes algorithms to visualise and measure networks of brain activity in such patients. These outputs are designed to enable clinicians better diagnose the state of awareness in patients, and prognosticate recovery from disorders of consciousness.

These networks are estimated by applying sophisticated signal processing methods to electrical activity data collected from patients' brains at their bedside, in collaboration with clinical partners. We have developed and validated metrics to characterise the networks measured with these data. Further, our pipeline applies machine learning to automatically classify the state of consciousness in individual patients based on their brain networks. Most importantly, the software prototype has been designed in such a way that it can be deployed along with high-density EEG systems at the bedside in rehabilitation centres where patients are resident.

![](https://github.com/srivaschennu/MOHAWK/blob/master/Chennu_et_al_2017.jpg)

_Brain networks in two behaviourally similar vegetative patients (left and middle), but one of whom imagined playing tennis (middle panel), alongside a healthy adult (right panel). From [Chennu et al., 2017, Brain](https://academic.oup.com/brain/article-lookup/doi/10.1093/brain/awx163)._

# Download

The MOHAWK pipeline packaged up as a MATLAB App can be downloaded from github: 

[https://github.com/srivaschennu/MOHAWK/raw/master/MOHAWK.mlappinstall](https://github.com/srivaschennu/MOHAWK/raw/master/MOHAWK.mlappinstall)

The underlying source code, along with supporting code for data analysis, is available in this source repository:

[https://github.com/srivaschennu/MOHAWK](https://github.com/srivaschennu/MOHAWK)

# Further Reading
The underpinning academic research can be found in the following papers:

Chennu, S., Annen, J., Wannez, S., Thibaut, A., Chatelle, C., Cassol, H., Martens, G., Schnakers, C., Gosseries, O., Menon, D. & Laureys, S. 2017. [Brain networks predict metabolism, diagnosis and prognosis at the bedside in disorders of consciousness](https://academic.oup.com/brain/article/doi/10.1093/brain/awx163/3896394/Brain-networks-predict-metabolism-diagnosis-and?guestAccessKey=37194adc-cf03-49fd-a505-5df2afce0b79). Brain, 140, 2120-2132.

Bareham, C. A., Allanson, J., Roberts, N., Hutchinson, P. J. A., Pickard, J. D., Menon, D. K. & Chennu, S. 2018. [Longitudinal Bedside Assessments of Brain Networks in Disorders of Consciousness: Case Reports From the Field](https://www.frontiersin.org/articles/10.3389/fneur.2018.00676/full). Frontiers in Neurology, 9, 676.

Chennu, S., Finoia, P., Kamau, E., Allanson, J., Williams, G. B., Monti, M. M., Noreika, V., Arnatkeviciute, A., Canales-Johnson, A., Olivares, F., Cabezas-Soto, D., Menon, D. K., Pickard, J. D., Owen, A. M. & Bekinschtein, T. A. 2014. [Spectral signatures of reorganised brain networks in disorders of consciousness](http://www.ploscompbiol.org/article/info:doi/10.1371/journal.pcbi.1003887). PLOS Computational Biology, 10, e1003887.

# License

MOHAWK is distributed open source, and is licensed under the [GNU General Public License](https://www.gnu.org/licenses/gpl.html). It builds upon excellent open source software including [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) and [FieldTrip](http://www.fieldtriptoolbox.org/), which are also similarly licensed.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

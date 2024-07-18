Simiocencu Andrei 341C2

Am realizat implementarea plecand de la for-ul din cpu_miner pe care l-am paralelizat astfel:
Am luat formulele folosite pentru a calcula index-ul si stride-ul din laboratorul 6 intrucat am
observat ca sunt folosite pentru a paraleliza o bucla de tip for.

Am folosit spatiul unificat de memorie pentru a evita copierea de pe host pe device si invers.
Astfel am putut sa dau kernelului ca argumente variabilele care vor stoca hash-ul, respectiv
nonce-ul direct, iar thread-urile le updateaza atunci cand gasesc un hash corect.

Functiile pe care nu le-am putut utiliza in kernel le-am inlocuit cu cele din utils.cu
Fiecare thread are propriile sale variabile locale folosite pentru a calcula hash-ul, am 
ales aceasta abordare pentru a evita suprascrierea acestor variabile de thread-uri diferite
si pentru a evita comportament nedefinit.

Folosesc un int de tip __device__ pentru a notifica thread-urile cand a fost gasit un nonce
care genereaza un hash corect, oprindu-le astfel executia si salvand astfel timp.
La fiecare iteratie de for se va verifica acest flag.

In ceea ce priveste numarul de block-uri si thread-uri/block, initial am facut implementarea
cu 1 block cu 1 thread pentru a ma asigura ca nu exista probleme de sincronizare.
Ulterior am observat ca implementarea mea functioneaza atunci cand numarul de thread-uri
e multiplu de nr de block-uri. Am observat in labul 06 ca se folosesc 256 de thread-uri
si am testat cu 256 de block-uri cu 512 thread-uri si am observat ca primesc rezultate
corect constant la viteze foarte bune si am ramas cu aceste valori.

Atunci cand foloseam 1 block cu 1 thread aveam timpi de ~50 secunde. Chiar daca e un timp mare
mi s-a parut interesant ca un singur thread de GPU a reusit un astfel de timp, pe cand un
CPU cu toate core-urile sale a reusit 2 secunde. Atunci cand folosesc toate resursele
GPU-ului rezultatul e aproape instant, ceea ce demonstreaza puterea GPU-ului cand vine
vorba de operatii matematice complexe.

In final eliberez memoria cu cudaFree pentru a evita leak-uri.


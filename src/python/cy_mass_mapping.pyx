# import both numpy and the Cython declarations for numpy
import numpy as np
cimport numpy as np
import pyssht as ssht
cimport cy_mass_mapping as mm



#----------------------------------------------------------------------------------------------------#

def lm2lm_hp(np.ndarray[double complex, ndim=1, mode="c"] f_lm not None, int L):

        cdef np.ndarray[complex, ndim=1] f_lm_hp
        cdef int el, em, index

        f_lm_hp = np.empty([L*(L+1)/2,], dtype=complex)
        
        for el from 0 <= el < L:
                        for em from 0 <= em <= el:
                                        index = mm.cy_healpy_lm2ind(el, em, L)
                                        f_lm_hp[index] = f_lm[ el * el + el + em ]

        return f_lm_hp

#----------------------------------------------------------------------------------------------------#

def lm_hp2lm(np.ndarray[double complex, ndim=1, mode="c"] flm_hp not None, int L):

        cdef np.ndarray[complex, ndim=1] f_lm
        cdef int el, em, index

        f_lm = np.empty([L*L,], dtype=complex)
        for el from 0 <= el < L:
                        f_lm[ el * el + el] = flm_hp[mm.cy_healpy_lm2ind(el, 0, L)]  # m=0 case
                        for em from 1 <= em <= el:
                                        index = mm.cy_healpy_lm2ind(el, em, L)
                                        f_lm[ el * el + el - em ] = pow(-1.0, -em) * (flm_hp[index]).conjugate()
                                        f_lm[ el * el + el + em ] = flm_hp[index]

        return f_lm

#----------------------------------------------------------------------------------------------------#

def healpy_lm2ind(int el, int em, int L):
        return em*(2*L-1-em)/2+el

def healpy_ind2lm(int ind, int L):

    cdef int n_elements = L, m=0, el

    while (True):
        if ind >= n_elements:
            ind -= n_elements
            n_elements -= <int>1
            m += 1
        else:
            el = ind + m
            return (el, m)



#--------------------------------------------------------------#

def generate_kappa_lm_hp(np.ndarray[double, ndim=1, mode="c"] Cl not None, int L, int seed=-1):
# generate converage harmonic coefs in HEALPix lm convention
    cdef np.ndarray[complex, ndim=1] k_lm
    cdef int el, em, index

    k_lm = np.empty(((L*L+L)/2,), dtype=complex)

    if seed > -1:
        np.random.seed(seed)

    k_lm[0] = 0.0; k_lm[1] = 0.0; k_lm[2] = 0.0; k_lm[3] = 0.0;

    for el in range(2,L):
        index = mm.cy_healpy_lm2ind(el, 0, L)
        k_lm[index] = np.random.randn()*np.sqrt(Cl[el])
        for em in range(1,el+1):
            index = mm.cy_healpy_lm2ind(el, em, L)
            k_lm[index] = (np.random.randn()+ 1j*np.random.randn())*np.sqrt(Cl[el])
    
    return k_lm
    
#--------------------------------------------------------------#

def generate_kappa_lm_mw(np.ndarray[double, ndim=1, mode="c"] Cl not None, int L, int seed=-1):
# generate converage harmonic coefs in SSHT lm convention
    cdef np.ndarray[complex, ndim=1] k_lm
    cdef int el, em, index, index2

    k_lm = np.empty((L*L,), dtype=complex)

    if seed > -1:
        np.random.seed(seed)

    k_lm[0] = 0.0; k_lm[1] = 0.0; k_lm[2] = 0.0; k_lm[3] = 0.0;

    for el in range(2,L):
        index = mm.cy_mw_elm2ind(el, 0)
        k_lm[index] = np.random.randn()*np.sqrt(Cl[el])
        for em in range(1,el+1):
            index  = mm.cy_mw_elm2ind(el, em)
            k_lm[index] = (np.random.randn()+ 1j*np.random.randn())*np.sqrt(Cl[el])
            index2 = mm.cy_mw_elm2ind(el,-em)
            k_lm[index2] = pow(-1.0, -em) * (k_lm[index] ).conjugate()
    return k_lm

#--------------------------------------------------------------#


def kappa_lm_to_gamma_lm_mw(np.ndarray[double complex, ndim=1, mode="c"] k_lm not None, int L):
# converting converace to shear in harmonic space in SSHT lm convention
    cdef np.ndarray[complex, ndim=1] gamma_lm
    cdef int el, em, index
    cdef float D_ell

    gamma_lm = np.empty(L*L, dtype=np.complex_)

    gamma_lm[0] = 0.0; gamma_lm[1] = 0.0; gamma_lm[2] = 0.0; gamma_lm[3] = 0.0
    
    for ell in range(2,L):
        D_ell = np.sqrt((<float>ell+2.0)*(<float>ell-1.0)/((<float>ell+1.0)*<float>ell))
        for em in range(-ell,ell+1):
            index = mm.cy_mw_elm2ind(ell, em)
            gamma_lm[index] = <complex>D_ell * k_lm[index]
            
    return gamma_lm

#--------------------------------------------------------------#


def kappa_lm_to_gamma_lm_hp(np.ndarray[double complex, ndim=1, mode="c"] k_lm not None, int L):
# converting converace to shear in harmonic space in healpy lm convention
    cdef np.ndarray[complex, ndim=1] gamma_E_lm, gamma_B_lm
    cdef int el, em, index
    cdef float D_ell

    gamma_E_lm = np.empty((L*(L+1)/2,), dtype=complex)
    gamma_B_lm = np.zeros((L*(L+1)/2,), dtype=complex)

    gamma_E_lm[0] = 0.0; gamma_E_lm[1] = 0.0; gamma_E_lm[2] = 0.0; gamma_E_lm[3] = 0.0
    
    for ell in range(2,L):
        D_ell = np.sqrt((<float>ell+2.0)*(<float>ell-1.0)/((<float>ell+1.0)*<float>ell))
        for em in range(0,ell+1):
            index = mm.cy_healpy_lm2ind(ell, em, L)
            gamma_E_lm[index] = <complex>D_ell * k_lm[index]
            
    return gamma_E_lm, gamma_B_lm

def gamma_lm_to_kappa_lm_mw(np.ndarray[double complex, ndim=1, mode="c"] gamma_lm not None, int L, float sigma=-1):

    cdef np.ndarray[complex, ndim=1] kappa_lm
    cdef int el, em, index
    cdef float D_ell

    kappa_lm = np.empty(L*L, dtype=np.complex_)

    kappa_lm[0] = 0.0; kappa_lm[1] = 0.0; kappa_lm[2] = 0.0; kappa_lm[3] = 0.0
    
    for ell in range(2,L):
        D_ell = np.sqrt((<float>ell+2.0)*(<float>ell-1.0)/((<float>ell+1.0)*<float>ell))
        if sigma > 0.0:
            guassian = np.exp(-<float>ell*<float>ell*sigma*sigma)
        for em in range(-ell,ell+1):
            index = mm.cy_mw_elm2ind(ell, em)
            kappa_lm[index] = gamma_lm[index]/<complex>D_ell
            if sigma > 0.0:
                kappa_lm[index] = guassian*kappa_lm[index]
            
    return kappa_lm


def gamma_lm_to_kappa_lm_hp(np.ndarray[double complex, ndim=1, mode="c"] gamma_E_lm not None, \
    np.ndarray[double complex, ndim=1, mode="c"] gamma_B_lm not None, int L, float sigma=-1):

    cdef np.ndarray[complex, ndim=1] kappa_E_lm, kappa_B_lm
    cdef int el, em, index
    cdef float D_ell, guassian

    kappa_E_lm = np.empty((L*(L+1)/2,), dtype=np.complex_)
    kappa_B_lm = np.empty((L*(L+1)/2,), dtype=np.complex_)

    kappa_E_lm[mm.cy_healpy_lm2ind(0, 0, L)] = 0.0; 
    kappa_E_lm[mm.cy_healpy_lm2ind(1, 0, L)] = 0.0; 
    kappa_E_lm[mm.cy_healpy_lm2ind(1, 1, L)] = 0.0;
    
    kappa_B_lm[mm.cy_healpy_lm2ind(0, 0, L)] = 0.0; 
    kappa_B_lm[mm.cy_healpy_lm2ind(1, 0, L)] = 0.0; 
    kappa_B_lm[mm.cy_healpy_lm2ind(1, 1, L)] = 0.0;
    
    for ell in range(2,L):
        D_ell = np.sqrt((<float>ell+2.0)*(<float>ell-1.0)/((<float>ell+1.0)*<float>ell))
        if sigma > 0.0:
            guassian = np.exp(-<float>ell*<float>ell*sigma*sigma)
        for em in range(0,ell+1):
            index = mm.cy_healpy_lm2ind(ell, em, L)
            kappa_E_lm[index] = gamma_E_lm[index]/<complex>D_ell
            kappa_B_lm[index] = gamma_B_lm[index]/<complex>D_ell
            if sigma > 0.0:
                kappa_E_lm[index] = kappa_E_lm[index]*guassian
                kappa_B_lm[index] = kappa_B_lm[index]*guassian

    return kappa_E_lm, kappa_B_lm

def gamma_to_kappa_mw(np.ndarray[complex, ndim=2, mode="c"] gamma not None, int L, str Method="MW", float sigma=-1):

    cdef np.ndarray[complex, ndim=1] gamma_lm, k_lm
    cdef np.ndarray[long, ndim=2] mask
    cdef np.ndarray[complex, ndim=2] k_mw
    cdef int i, j, n_theta, n_phi

    n_theta, n_phi = ssht.sample_shape(L,Method=Method)

    mask = np.full((n_theta,n_phi),1,dtype=int)

    for i in range(n_theta):
        for j in range(n_phi):
            if np.isnan(gamma[i,j]):
                mask[i,j] = 0
                gamma[i,j] = 0.0

    gamma_lm = ssht.forward(gamma, L, Method=Method, Spin=2)

    k_lm = gamma_lm_to_kappa_lm_mw(gamma_lm, L, sigma=sigma)

    k_mw = ssht.inverse(k_lm, L, Method=Method)

    for i in range(n_theta):
        for j in range(n_phi):
            if mask[i,j] == 0:
                gamma[i,j] = np.nan + 1j*np.nan
                k_mw[i,j] = np.nan + 1j*np.nan


    return k_mw

def gamma_to_kappa_plane(np.ndarray[complex, ndim=2, mode="c"] gamma not None, float delta_theta, float delta_phi, float sigma=-1):

    cdef np.ndarray[complex, ndim=2] gamma_kk, k_kk, k_mw
    cdef np.ndarray[np.float_t, ndim=2] mask
    cdef int i, j, N, M
    cdef complex D_ij
    cdef float l1, l2

    N = gamma.shape[0]
    M = gamma.shape[1]

    mask = np.zeros((N,M), dtype=float)

    for i in range(N):
        for j in range(M):
            if np.isnan(gamma[i,j]):
                gamma[i,j] = 0.0 + 0.0j
                mask[i,j]  = np.nan

    gamma_kk = np.fft.fft2(gamma,norm="ortho")

    gamma_kk = np.fft.fftshift(gamma_kk)

    k_kk = np.empty((N,M), dtype=complex)

    for i in range(N):
        for j in range(M):
            l1 = (<float>i-<float>(N/2))/delta_theta; 
            l2 = (<float>N*(<float>j-<float>(M/2)))/(<float>M*delta_phi);
#            l1 = (<float>i-<float>(N/2)) 
#            l2 = (<float>N*(<float>j-<float>(M/2)))/(<float>M);
        
            if not(abs(l1) < 1E-6 and abs(l2) < 1E-6):
                D_ij = (l1*l1 - l2*l2 - 2*1j*l1*l2)/(l1*l1+l2*l2)
                k_kk[i,j] = gamma_kk[i,j]*D_ij
                if sigma > 0.0:
                    k_kk[i,j] = k_kk[i,j]*np.exp(-((l1*l1*sigma*sigma/(N*N))+(l2*l2*sigma*sigma/(M*M)))*np.pi*np.pi)
#                    print l1, sigma,  l1*l1*sigma*sigma/N
            else:
                k_kk[i,j] = 0.0

    k_kk = np.fft.ifftshift(k_kk)

    k_mw = np.fft.ifft2(k_kk,norm="ortho")

    for i in range(N):
        for j in range(M):
            if np.isnan(mask[i,j]):
                gamma[i,j] = np.nan + 1j*np.nan
                k_mw[i,j] = np.nan + 1j*np.nan

    return k_mw
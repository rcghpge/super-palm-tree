! Print matrix A to screen
subroutine print_matrix(n,m,A)
  implicit none
  integer, intent(in) :: n
  integer, intent(in) :: m
  real, intent(in) :: A(n, m)

  integer :: i

  do i = 1, n
    print *, A(i, 1:m)
  end do

end subroutine print_matrix

program call_sub
  implicit none

  real :: mat1(10, 20)
  real :: mat2(10, 20)

  mat1(:,:) = 6.0
  mat2(:,:) = 7.0

  call print_matrix(10, 20, mat1)
  print *, "----"
  call print_matrix(10, 20, mat2)

end program call_sub

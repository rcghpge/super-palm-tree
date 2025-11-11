! Calculate the area of a traingle
program calc_area
  implicit none
  real :: A, B, C, S, area

  print *, "Enter three sides of the triangle:"
  read *, A, B, C

  print *, "Sides read: ", A, B, C

  ! Triangle inequality check
  if ((A + B <= C) .or. (A + C <= B) .or. (B + C <= A)) then
    print *, "Invalid triangle sides. Cannot form a triangle."
    stop
  end if

  S = (A + B + C) / 2.0
  area = sqrt(S * (S - A) * (S - B) * (S - C))

  print *, "Area =", area

end program calc_area

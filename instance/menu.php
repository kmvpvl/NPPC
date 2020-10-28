<nav class="navbar navbar-expand-md navbar-dark bg-dark ml-0">
	<a class="navbar-brand" href="#">My factory
	</a>
	<!--button type="button" class="btn btn-success">Refresh</button-->
	<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
		<span class="navbar-toggler-icon"></span>
	</button>
	
	<div class="collapse navbar-collapse" id="navbarSupportedContent">
	<ul class="navbar-nav mr-auto">
		<li class="nav-item active">
			<a class="nav-link" instance="factory.php" id="menuFactory">Factory</a>
		</li>
		<li class="nav-item" >
			<a class="nav-link" instance="orders.php" id="menuOrders">Orders</a>
		</li>
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Master Data</a>
			<div class="dropdown-menu" aria-labelledby="navbarDropdown">
				<a class="dropdown-item" href="#">Factory, workcentres, routes</a>
				<a class="dropdown-item" href="#">Products</a>
				<a class="dropdown-item" href="#">Customers</a>
				<a class="dropdown-item" href="#">Suppliers</a>
				<div class="dropdown-divider"></div>
				<a class="dropdown-item" href="#">Users</a>
				<a class="dropdown-item" href="#">Settings</a>
			</div>
		</li>
	</ul>
	<ul class="navbar-nav lr-auto">
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">David Rhuxel</a>
			<div class="dropdown-menu" aria-labelledby="navbarDropdown">
				<a class="dropdown-item" href="#">My settings</a>
				<a class="dropdown-item" href="#">My subscriptions</a>
				<a class="dropdown-item" href="#">Logout</a>
			</div>
		</li>
	</ul>
	</div>
</nav>